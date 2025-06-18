module SortableHelper
  # Lookup table for sort attributes by resource type
  SORT_ATTRIBUTES_BY_RESOURCE = {
    'players' => {
      'first_name' => 'First Name',
      'last_name' => 'Last Name', 
      'team_name' => 'Team',
      'league_name' => 'League',
      'sport_name' => 'Sport',
      'position_name' => 'Position',
      'random' => 'Random',
      'shuffle' => 'Shuffle'
    },
    'leagues' => {
      'alphabetical' => 'Alphabetical',
      'country_name' => 'Country',
      'sport_name' => 'Sport', 
      'random' => 'Random',
      'shuffle' => 'Shuffle'
    },
    'divisions' => {
      'name' => 'Name',
      'abbreviation' => 'Abbreviation',
      'random' => 'Random',
      'shuffle' => 'Shuffle'
    }
  }.freeze

  def sort_links_for(resource_collection, resource_type = nil)
    resource_type ||= infer_resource_type(resource_collection)
    sort_attributes = SORT_ATTRIBUTES_BY_RESOURCE[resource_type] || {}
    
    tag.div class: "sort-links-container" do
      content = ""
      
      if @sort_service.sort_params.any?
        content << hierarchical_sort_display_for(resource_type)
        content << tag.hr(class: "sort-separator")
      end
      
      content << tag.div(class: "sort-links-group") do
        tag.span("Sort by:", class: "sort-label") +
        sort_attributes.map { |attr, label| 
          hierarchical_sort_link_for(attr, label, resource_type) 
        }.join.html_safe
      end
      
      content.html_safe
    end
  end

  def hierarchical_sort_display_for(resource_type)
    return "" if @sort_service.sort_params.empty?
    
    tag.div class: "hierarchical-sort-display" do
      tag.span("Sort order (first → refinements):", class: "sort-chain-label") +
      tag.div(class: "sort-chain") do
        @sort_service.sort_params.filter_map.with_index do |sort, index|
          next if sort[:direction] == 'inactive'
          
          sort_resource = determine_sort_resource(sort[:attribute], resource_type)
          
          tag.div(class: "sort-chain-item", data: { sort_resource: sort_resource }) do
            tag.span("#{index + 1}.", class: "sort-chain-priority") +
            tag.span(humanize_sort_attribute_for(sort[:attribute], resource_type), class: "sort-chain-attribute") +
            tag.span(humanize_sort_direction(sort[:direction], sort[:attribute]), class: "sort-chain-direction") +
            sort_direction_controls_for(sort[:attribute], sort[:direction], resource_type)
          end
        end.join.html_safe
      end
    end
  end

  def hierarchical_sort_link_for(attribute, label, resource_type)
    current_direction = @sort_service.direction_for(attribute)
    priority = @sort_service.priority_for(attribute)
    
    css_classes = build_sort_link_classes(current_direction, priority)
    sort_resource = determine_sort_resource(attribute, resource_type)
    
    toggle_service = @sort_service.toggle_sort(attribute)
    sort_param = toggle_service.to_param
    
    url_params = request.query_parameters.except('sort')
    url_params[:sort] = sort_param unless sort_param.empty?
    
    path_method = "#{resource_type}_path"
    
    link_to send(path_method, url_params), 
            class: css_classes, 
            data: { turbo_preload: false, resource: sort_resource } do
      content = ""
      
      if priority
        content << tag.span("#{priority}", class: "sort-priority-badge")
      end
      
      content << label
      
      if current_direction != 'inactive'
        content << " " + tag.span(direction_icon(current_direction, attribute), class: "sort-direction-icon")
      end
      
      content.html_safe
    end
  end

  def sort_direction_controls_for(attribute, current_direction, resource_type)
    tag.div(class: "sort-direction-controls") do
      if %w[random shuffle].include?(attribute.to_s)
        random_classes = current_direction == 'random' ? 
          'sort-direction-link sort-direction-active' : 
          'sort-direction-link sort-direction-inactive'
        
        shuffle_classes = current_direction == 'shuffle' ? 
          'sort-direction-link sort-direction-active' : 
          'sort-direction-link sort-direction-inactive'
        
        random_link = direct_sort_link_for(attribute, 'random', '🎲', random_classes, resource_type)
        shuffle_link = direct_sort_link_for(attribute, 'shuffle', '🔀', shuffle_classes, resource_type)
        remove_link = direct_sort_link_for(attribute, 'inactive', '✕', 'sort-direction-link sort-direction-remove', resource_type)
        
        random_link + shuffle_link + remove_link
      else
        asc_classes = current_direction == 'asc' ? 
          'sort-direction-link sort-direction-active' : 
          'sort-direction-link sort-direction-inactive'
        
        asc_link = direct_sort_link_for(attribute, 'asc', '↑', asc_classes, resource_type)
        
        desc_classes = current_direction == 'desc' ? 
          'sort-direction-link sort-direction-active' : 
          'sort-direction-link sort-direction-inactive'
        
        desc_link = direct_sort_link_for(attribute, 'desc', '↓', desc_classes, resource_type)
        remove_link = direct_sort_link_for(attribute, 'inactive', '✕', 'sort-direction-link sort-direction-remove', resource_type)
        
        asc_link + desc_link + remove_link
      end
    end
  end

  def direct_sort_link_for(attribute, target_direction, icon, css_classes, resource_type)
    new_service = create_service_with_direction_for(attribute, target_direction)
    sort_param = new_service.to_param
    
    url_params = request.query_parameters.except('sort')
    url_params[:sort] = sort_param unless sort_param.empty?
    
    path_method = "#{resource_type}_path"
    
    link_to send(path_method, url_params), 
            class: css_classes, 
            data: { turbo_preload: false },
            title: "#{humanize_sort_attribute_for(attribute, resource_type)} #{target_direction == 'inactive' ? 'remove' : target_direction}" do
      tag.span(icon, class: "sort-direction-icon")
    end
  end

  def create_service_with_direction_for(attribute, target_direction)
    new_params = @sort_service.sort_params.dup
    existing_index = @sort_service.find_sort_index(attribute)
    
    if existing_index
      if target_direction == 'inactive'
        new_params.delete_at(existing_index)
      else
        new_params[existing_index][:direction] = target_direction
      end
    end
    
    HierarchicalSortService.new(new_params, @sort_service.max_levels)
  end

  def humanize_sort_attribute_for(attribute, resource_type)
    sort_attributes = SORT_ATTRIBUTES_BY_RESOURCE[resource_type] || {}
    sort_attributes[attribute.to_s] || attribute.to_s.humanize
  end

  private

  def infer_resource_type(collection)
    # Try to infer from the collection variable name or class
    case collection
    when /players/i
      'players'
    when /leagues/i
      'leagues'
    when /divisions/i
      'divisions'
    else
      # Try to infer from controller
      controller_name = params[:controller]
      controller_name&.singularize&.pluralize || 'unknown'
    end
  end

  def build_sort_link_classes(direction, priority)
    base_class = "hierarchical-sort-link"
    
    case direction
    when 'inactive'
      "#{base_class} sort-link-inactive"
    when 'asc', 'desc', 'random', 'shuffle'
      classes = "#{base_class} sort-link-active"
      classes += " sort-link-priority-#{priority}" if priority
      classes
    else
      "#{base_class} sort-link-inactive"
    end
  end

  def direction_icon(direction, attribute)
    case direction
    when 'asc'
      '↑'
    when 'desc'
      '↓'
    when 'random'
      '🎲'
    when 'shuffle'
      '🔀'
    else
      ''
    end
  end

  def humanize_sort_direction(direction, attribute)
    case direction
    when 'asc'
      if %w[random shuffle].include?(attribute.to_s)
        'active'
      else
        'ascending'
      end
    when 'desc'
      'descending'
    when 'random'
      'random'
    when 'shuffle'
      'shuffle'
    else
      direction.to_s
    end
  end

  def determine_sort_resource(attribute, resource_type)
    # Map sort attributes to their corresponding resource types
    case attribute.to_s
    when 'sport_name'
      'sport'
    when 'league_name'
      'league'  
    when 'conference_name'
      'conference'
    when 'division_name'
      'division'
    when 'team_name'
      'team'
    when 'first_name', 'last_name'
      'player'
    when 'position_name'
      'position'
    when 'country_name'
      'country'
    when 'state_name'
      'state'
    when 'city_name'
      'city'
    when 'stadium_name'
      'stadium'
    else
      # Default to the resource type being sorted if no specific mapping
      case resource_type
      when 'players'
        'player'
      when 'leagues'
        'league'
      when 'divisions'
        'division'
      when 'teams'
        'team'
      else
        resource_type&.singularize || 'default'
      end
    end
  end
end