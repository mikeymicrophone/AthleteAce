module PlayersHelper
  # Display player name with logo
  def player_name_display player
    tag.div class: "record-name" do
      display_name_with_lazy_logo(player, logo_attribute: :image_url)
    end
  end
  
  # Display player metadata (team, league, sport)
  def player_metadata_display player
    tag.div class: "record-metadata" do
      link_to_name(player.team) + 
      " | " + 
      display_name_with_lazy_logo(player.league) + 
      " | " + 
      display_name_with_lazy_logo(player.sport, logo_attribute: :icon_url)
    end
  end
  
  # Display player position tag if available
  def player_position_display player
    if player.primary_position
      tag.div player.primary_position.name, class: "record-tag"
    end
  end
  
  # Combine all player info elements
  def player_info_display player
    player_name_display(player) +
    player_metadata_display(player) +
    player_position_display(player)
  end

  def player_photo_display player
    tag.div class: "player-photo-container" do
      if player.photo_urls.present?
        tag.img src: player.photo_urls.sample, alt: player.full_name, class: "player-photo"
      else
        tag.div class: "player-photo-placeholder" do
          tag.i class: "fa-solid fa-user"
        end
      end
    end
  end

  def player_sort_links
    tag.div class: "sort-links-container" do
      content = ""
      
      # Hierarchical sort display
      if @sort_service.sort_params.any?
        content << hierarchical_sort_display
        content << tag.hr(class: "sort-separator")
      end
      
      # Individual sort links
      content << tag.div(class: "sort-links-group") do
        tag.span("Sort by:", class: "sort-label") +
        hierarchical_sort_link(:first_name, "First Name") +
        hierarchical_sort_link(:last_name, "Last Name") +
        hierarchical_sort_link(:team_name, "Team") +
        hierarchical_sort_link(:league_name, "League") +
        hierarchical_sort_link(:sport_name, "Sport") +
        hierarchical_sort_link(:position_name, "Position") +
        hierarchical_sort_link(:random, "Random") +
        hierarchical_sort_link(:shuffle, "Shuffle")
      end
      
      content.html_safe
    end
  end
  
  # Display the current hierarchical sort chain
  def hierarchical_sort_display
    return "" if @sort_service.sort_params.empty?
    
    tag.div class: "hierarchical-sort-display" do
      tag.span("Current sort order:", class: "sort-chain-label") +
      tag.div(class: "sort-chain") do
        @sort_service.sort_params.filter_map.with_index do |sort, index|
          next if sort[:direction] == 'inactive'
          
          tag.div(class: "sort-chain-item") do
            tag.span("#{index + 1}.", class: "sort-chain-priority") +
            tag.span(humanize_sort_attribute(sort[:attribute]), class: "sort-chain-attribute") +
            tag.span(humanize_sort_direction(sort[:direction], sort[:attribute]), class: "sort-chain-direction")
          end
        end.join.html_safe
      end
    end
  end
  
  # Create a hierarchical sort link with three states
  def hierarchical_sort_link(attribute, label = nil, options = {})
    label ||= attribute.to_s.humanize
    current_direction = @sort_service.direction_for(attribute)
    priority = @sort_service.priority_for(attribute)
    
    # Determine CSS classes based on current state
    css_classes = build_sort_link_classes(current_direction, priority)
    
    # Generate the URL for toggling this sort
    toggle_service = @sort_service.toggle_sort(attribute)
    sort_param = toggle_service.to_param
    
    # Build the new URL preserving other parameters
    url_params = request.query_parameters.except('sort')
    url_params[:sort] = sort_param unless sort_param.empty?
    
    link_to players_path(url_params), class: css_classes do
      content = ""
      
      # Add priority indicator if this sort is active
      if priority
        content << tag.span("#{priority}", class: "sort-priority-badge")
      end
      
      content << label
      
      # Add direction indicator
      if current_direction != 'inactive'
        content << " " + tag.span(direction_icon(current_direction, attribute), class: "sort-direction-icon")
      end
      
      content.html_safe
    end
  end
  
  # Build CSS classes for sort links based on state and priority
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
  
  # Get appropriate icon for sort direction
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
  
  # Humanize sort attribute names
  def humanize_sort_attribute(attribute)
    case attribute.to_s
    when 'team_name'
      'Team'
    when 'league_name'
      'League'
    when 'sport_name'
      'Sport'
    when 'position_name'
      'Position'
    when 'first_name'
      'First Name'
    when 'last_name'
      'Last Name'
    else
      attribute.to_s.humanize
    end
  end
  
  # Humanize sort direction
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
end
