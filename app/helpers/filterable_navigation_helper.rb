module FilterableNavigationHelper
  # Generate a navigation bar for filtered resources
  #
  # @param current_resource [Symbol] The current resource being viewed
  # @param current_filters [Hash] Hash of current filters (e.g., { sport: @sport })
  # @param options [Hash] Options for customizing the navigation
  # @return [String] HTML navigation bar
  def filterable_navigation(current_resource, current_filters = {}, options = {})
    # Default options
    default_options = {
      container_class: 'mb-6 bg-white rounded-lg shadow overflow-x-auto',
      nav_class: 'flex space-x-1 p-2',
      item_class: 'px-4 py-2 text-sm font-medium rounded-md',
      active_class: 'bg-blue-600 text-white',
      inactive_class: 'text-gray-700 hover:bg-gray-100',
      resources: [:sports, :leagues, :teams, :players, :divisions, :conferences]
    }
    
    # Merge provided options with defaults
    options = default_options.merge options
    
    # Generate the navigation bar
    content_tag :div, class: options[:container_class] do
      content_tag :nav, class: options[:nav_class] do
        nav_items = options[:resources].map do |resource|
          # Determine if this is the current resource
          is_active = resource == current_resource
          
          # Build the path with current filters
          path = filtered_path resource, current_filters
          
          # Build the class list
          item_class = options[:item_class] + ' ' + 
                      (is_active ? options[:active_class] : options[:inactive_class])
          
          # Create the link
          link_to resource.to_s.humanize, path, class: item_class
        end
        
        safe_join nav_items
      end
    end
  end
  
  # Generate a context-aware secondary navigation for related resources
  # This shows links to related resources based on the current filters
  #
  # @param current_resource [Symbol] The current resource being viewed
  # @param current_filters [Hash] Hash of current filters
  # @param options [Hash] Options for customizing the navigation
  # @return [String] HTML secondary navigation
  def filterable_context_nav(current_resource, current_filters = {}, options = {})
    return '' if current_filters.empty?
    
    # Default options
    default_options = {
      container_class: 'mb-6 bg-white rounded-lg shadow-sm',
      heading_class: 'px-4 py-2 text-sm font-medium text-gray-700 border-b',
      nav_class: 'grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-2 p-4',
      item_class: 'px-3 py-2 text-sm rounded flex items-center',
      item_icon_class: 'mr-2 text-gray-400',
      active_class: 'bg-blue-50 text-blue-700 border border-blue-200',
      inactive_class: 'text-gray-700 hover:bg-gray-50 border border-transparent'
    }
    
    # Merge provided options with defaults
    options = default_options.merge options
    
    # Get the main filter (first filter in hierarchy)
    primary_filter = sort_filters_by_hierarchy(current_filters).first
    return '' unless primary_filter
    
    # Primary filter key and object
    filter_key, filter_obj = primary_filter
    
    # Generate context-specific navigation
    content_tag :div, class: options[:container_class] do
      content = []
      
      # Add heading
      content << content_tag(:h3, "More #{filter_obj.name} Resources", class: options[:heading_class])
      
      # Add navigation links container
      content << content_tag(:div, class: options[:nav_class]) do
        nav_items = []
        
        # Generate appropriate related links based on the primary filter
        case filter_key
        when :sport
          related_resources = [:teams, :leagues, :players]
        when :league
          related_resources = [:teams, :conferences, :divisions, :players]
        when :team
          related_resources = [:players, :stadiums]
        when :conference
          related_resources = [:divisions, :teams]
        when :division
          related_resources = [:teams, :conferences]
        when :city, :state, :country
          related_resources = [:teams, :stadiums, :players]
        when :stadium
          related_resources = [:teams, :players]
        else
          related_resources = []
        end
        
        # Filter out the current resource
        related_resources.delete current_resource
        
        # Create links for each related resource
        related_resources.each do |resource|
          # Build the path with current filters
          path = filtered_path resource, current_filters
          
          # Determine if this is the current resource
          is_active = resource == current_resource
          
          # Build the class list
          item_class = options[:item_class] + ' ' + 
                      (is_active ? options[:active_class] : options[:inactive_class])
          
          # Create appropriate icon based on resource type
          icon = resource_icon_for resource
          
          # Create the link with icon
          nav_items << link_to(path, class: item_class) do
            safe_join [
              content_tag(:span, icon, class: options[:item_icon_class]),
              "#{filter_obj.name} #{resource.to_s.humanize}"
            ]
          end
        end
        
        safe_join nav_items
      end
      
      safe_join content
    end
  end
  
  private
  
  # Sort filters by a predefined hierarchy
  # This ensures we present filters in a logical order (e.g., sport -> league -> team)
  # @param filters [Hash] Hash of current filters
  # @return [Array] Sorted array of [filter_key, filter_object] pairs
  def sort_filters_by_hierarchy(filters)
    return [] if filters.empty?
    
    # Define the hierarchy of resources
    hierarchy = [
      :sport,
      :league,
      :conference,
      :division,
      :team,
      :country,
      :state,
      :city,
      :stadium,
      :player
    ]
    
    # Convert filters to array and sort by hierarchy position
    filters.to_a.sort do |(key_a, _), (key_b, _)|
      pos_a = hierarchy.index(key_a.to_sym) || 999
      pos_b = hierarchy.index(key_b.to_sym) || 999
      pos_a <=> pos_b
    end
  end
  
  # Get an appropriate icon for a resource type
  def resource_icon_for(resource)
    case resource
    when :sports
      '🏆'
    when :leagues
      '🏅'
    when :teams
      '👥'
    when :players
      '👤'
    when :divisions
      '📊'
    when :conferences
      '🏛️'
    when :stadiums
      '🏟️'
    when :countries
      '🌎'
    when :states
      '🗺️'
    when :cities
      '🏙️'
    else
      '📋'
    end
  end
end
