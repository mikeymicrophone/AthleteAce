module PlayersHelper

  def player_sort_links
    tag.div class: "flex flex-col md:flex-row justify-between items-center gap-4 mb-4" do
      tag.div class: "flex flex-wrap gap-2 items-center" do
        tag.span class: "text-sm text-gray-600 mr-1" do
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
  
  # Custom sort link helper that enhances Ransack's sort_link with Tailwind styling
  # @param search [Ransack::Search] The Ransack search object
  # @param attribute [Symbol] The attribute to sort by
  # @param label [String] Optional label for the link (defaults to humanized attribute)
  # @param options [Hash] Additional options for the link
  # @return [String] HTML for the sort link
  def tailwind_sort_link(search, attribute, label = nil, options = {})
    # Extract Tailwind-specific options
    class_base = options.delete(:class_base) || "px-3 py-1 text-sm rounded-md transition-colors duration-150"
    class_active = options.delete(:class_active) || "bg-indigo-100 text-indigo-700 font-medium"
    class_inactive = options.delete(:class_inactive) || "bg-gray-100 text-gray-700 hover:bg-gray-200"
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
        content << " " << tag.span(direction_arrow, class: "text-xs font-bold").to_s
      end
      content.html_safe
    end
  end
  
  # Helper to create a random sort link
  # @return [String] HTML for the random sort link
  def random_sort_link
    is_random = params[:random] == "true"
    css_classes = is_random ? 
      "px-3 py-1 text-sm rounded-md transition-colors duration-150 bg-indigo-100 text-indigo-700 font-medium" : 
      "px-3 py-1 text-sm rounded-md transition-colors duration-150 bg-gray-100 text-gray-700 hover:bg-gray-200"
    
    link_to players_path(random: true), class: css_classes do
      tag.i(class: "fa-solid fa-shuffle mr-1") + "Random"
    end
  end
  
  # Helper to create a search form for players
  # @param search [Ransack::Search] The Ransack search object
  # @return [String] HTML for the search form
  def player_search_form(search)
    search_form_for search, class: "mb-6" do |f|
      content = tag.div(class: "bg-white p-4 rounded-lg shadow-sm border border-gray-200") do
        concat(tag.h3("Filter Players", class: "text-lg font-medium text-gray-900 mb-3"))
        
        # Basic search fields
        concat(
          tag.div(class: "grid grid-cols-1 md:grid-cols-3 gap-4 mb-4") do
            # Name search field
            concat(
              tag.div do
                f.label(:full_name_cont, "Name contains", class: "block text-sm font-medium text-gray-700 mb-1") +
                f.search_field(:full_name_cont, class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm")
              end
            )
            
            # Team search field
            concat(
              tag.div do
                f.label(:team_name_cont, "Team", class: "block text-sm font-medium text-gray-700 mb-1") +
                f.search_field(:team_name_cont, class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm")
              end
            )
            
            # League search field
            concat(
              tag.div do
                f.label(:league_name_cont, "League", class: "block text-sm font-medium text-gray-700 mb-1") +
                f.search_field(:league_name_cont, class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm")
              end
            )
          end
        )
        
        # Advanced search section (collapsible)
        concat(
          tag.div(class: "mb-4", data: { controller: "collapse" }) do
            # Collapsible section toggle
            concat(
              tag.div(class: "flex items-center cursor-pointer mb-2", data: { action: "click->collapse#toggle" }) do
                tag.span("Advanced Filters", class: "text-sm font-medium text-indigo-600") +
                tag.i(class: "fas fa-chevron-down ml-1 text-indigo-600 text-xs")
              end
            )
            
            # Collapsible content
            concat(
              tag.div(class: "grid grid-cols-1 md:grid-cols-3 gap-4 hidden", data: { collapse_target: "content" }) do
                # Position search field
                concat(
                  tag.div do
                    f.label(:position_name_cont, "Position", class: "block text-sm font-medium text-gray-700 mb-1") +
                    f.search_field(:position_name_cont, class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm")
                  end
                )
                
                # Sport search field
                concat(
                  tag.div do
                    f.label(:sport_name_cont, "Sport", class: "block text-sm font-medium text-gray-700 mb-1") +
                    f.search_field(:sport_name_cont, class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm")
                  end
                )
                
                # Birth country search field
                concat(
                  tag.div do
                    f.label(:birth_country_name_cont, "Birth Country", class: "block text-sm font-medium text-gray-700 mb-1") +
                    f.search_field(:birth_country_name_cont, class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm")
                  end
                )
              end
            )
          end
        )
        
        # Form actions
        concat(
          tag.div(class: "flex items-center justify-end gap-2") do
            # Reset button
            concat(
              link_to("Reset", players_path, class: "rounded-md bg-white px-3.5 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50")
            )
            
            # Submit button
            concat(
              f.button(type: "submit", class: "rounded-md bg-indigo-600 px-3.5 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600") do
                tag.i(class: "fas fa-search mr-1") + "Search"
              end
            )
          end
        )
      end
      
      content
    end
  end
end
