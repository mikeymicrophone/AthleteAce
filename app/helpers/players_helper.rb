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
      tag.div class: "sort-links-group" do
        tag.span class: "sort-label" do
          "Sort by:"
        end
        tailwind_sort_link(@q, :first_name) +
        tailwind_sort_link(@q, :last_name) +
        tailwind_sort_link(@q, :team_name, "Team") +
        tailwind_sort_link(@q, :league_name, "League") +
        tailwind_sort_link(@q, :sport_name, "Sport") +
        tailwind_sort_link(@q, :position_name, "Position") +
        random_sort_link
      end
    end
  end
  
  # Custom sort link helper that enhances Ransack's sort_link with semantic styling
  # @param search [Ransack::Search] The Ransack search object
  # @param attribute [Symbol] The attribute to sort by
  # @param label [String] Optional label for the link (defaults to humanized attribute)
  # @param options [Hash] Additional options for the link
  # @return [String] HTML for the sort link
  def tailwind_sort_link(search, attribute, label = nil, options = {})
    # Extract styling options
    class_base = options.delete(:class_base) || "sort-link"
    class_active = options.delete(:class_active) || "sort-link-active"
    class_inactive = options.delete(:class_inactive) || "sort-link-inactive"
    icon = options.delete(:icon)
    
    # Determine if this sort is currently active
    current_sort = search.sorts.find { |s| s.name == attribute.to_s }
    is_active = current_sort.present?
    
    # Get the direction arrow if active
    direction_arrow = if is_active
      current_sort.dir == "asc" ? "↑" : "↓"
    else
      nil
    end
    
    # Build the CSS classes
    css_classes = is_active ? "#{class_base} #{class_active}" : "#{class_base} #{class_inactive}"
    
    # Call Ransack's sort_link with our custom options
    sort_link_options = options.merge(class: css_classes)
    
    # Create the link with custom content
    sort_link(search, attribute, label, sort_link_options) do
      content = ""
      if icon.present?
        content << tag.i(class: "#{icon} mr-1").to_s
      end
      content << (label || attribute.to_s.humanize)
      if direction_arrow
        content << " " << tag.span(direction_arrow, class: "sort-direction-indicator").to_s
      end
      content.html_safe
    end
  end
  
  # Helper to create a random sort link
  # @return [String] HTML for the random sort link
  def random_sort_link
    is_random = params[:random] == "true"
    css_classes = is_random ? "random-sort-link random-sort-link-active" : "random-sort-link random-sort-link-inactive"
    
    link_to players_path(random: true), class: css_classes do
      tag.i(class: "random-sort-icon #{icon_for_resource(:shuffle)}") + "Random"
    end
  end
end
