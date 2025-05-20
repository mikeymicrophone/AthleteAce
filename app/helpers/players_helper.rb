module PlayersHelper
  # Renders sorting options for players with active state indication and hierarchical sorting
  # @param players [ActiveRecord::Relation] The players collection
  # @return [String] HTML for the sorting options
  def sorting_scopes_for(players)
    # Get current sort parameters as an array
    current_sorts = if params[:sort].present?
      params[:sort].is_a?(Array) ? params[:sort] : [params[:sort]]
    else
      ["first_name"]
    end
    
    tag.div(class: "flex flex-col items-end gap-2") do
      # Primary sort options
      concat(
        tag.div(class: "flex flex-wrap gap-2 items-center") do
          # Label
          concat(tag.span("Primary sort:", class: "text-sm text-gray-600 mr-1"))
          
          # Primary sort options
          concat(primary_sort_link("First Name", "first_name", current_sorts))
          concat(primary_sort_link("Last Name", "last_name", current_sorts))
          concat(primary_sort_link("Team", "team_id", current_sorts))
          concat(primary_sort_link("League", "league_id", current_sorts))
          concat(primary_sort_link("Sport", "sport_id", current_sorts))
          concat(primary_sort_link("Position", "position_id", current_sorts))
          concat(primary_sort_link("Random", "random", current_sorts, icon: "fa-solid fa-shuffle"))
        end
      )
      
      # Only show secondary sort if a primary sort is selected and it's not random
      if current_sorts.present? && current_sorts.first != "random"
        concat(
          tag.div(class: "flex flex-wrap gap-2 items-center") do
            # First add the label
            concat(tag.span("Then by:", class: "text-sm text-gray-600 mr-1"))
            
            # Secondary sort options (exclude the primary sort and random)
            secondary_sort_options = [
              {label: "First Name", value: "first_name"},
              {label: "Last Name", value: "last_name"},
              {label: "Team", value: "team_id"},
              {label: "League", value: "league_id"},
              {label: "Sport", value: "sport_id"},
              {label: "Position", value: "position_id"}
            ].reject { |opt| opt[:value] == current_sorts.first }
            
            # Create links for secondary sort options
            secondary_sort_options.each do |option|
              concat(secondary_sort_link(option[:label], option[:value], current_sorts))
            end
          end
        )
      end
      
      # Show the current sort order if multiple sorts are applied
      if current_sorts.size > 1
        sort_names = current_sorts.map do |sort|
          case sort
          when "first_name" then "First Name"
          when "last_name" then "Last Name"
          when "team_id" then "Team"
          when "league_id" then "League"
          when "sport_id" then "Sport"
          when "position_id" then "Position"
          when "random" then "Random"
          else sort.humanize
          end
        end
        
        concat(
          tag.div(class: "text-xs text-gray-500 italic mt-1") do
            "Current sort: #{sort_names.join(' → ')}"
          end
        )
      end
    end
  end
  
  # Helper to create a primary sort link
  # @param label [String] The link text
  # @param sort_param [String] The sort parameter value
  # @param current_sorts [Array] The current sort parameters
  # @param icon [String] Optional Font Awesome icon class
  # @return [String] HTML for the sort link
  def primary_sort_link(label, sort_param, current_sorts, icon: nil)
    is_active = current_sorts.first == sort_param
    
    # For primary sort, we replace the entire sort array
    link_params = request.params.merge(sort: [sort_param])
    
    # Generate the link with appropriate styling
    link_to(link_params, class: sort_link_classes(is_active)) do
      if icon.present?
        tag.i(class: "#{icon} mr-1") + label
      else
        label
      end
    end
  end
  
  # Helper to create a secondary sort link
  # @param label [String] The link text
  # @param sort_param [String] The sort parameter value to add as secondary
  # @param current_sorts [Array] The current sort parameters
  # @return [String] HTML for the sort link
  def secondary_sort_link(label, sort_param, current_sorts)
    # Check if this sort is already in the chain
    is_active = current_sorts.size > 1 && current_sorts[1] == sort_param
    
    # Create a new sort array with this as the secondary sort
    new_sorts = [current_sorts.first, sort_param]
    
    # Preserve all existing params but update the sort array
    link_params = request.params.merge(sort: new_sorts)
    
    # Generate the link with appropriate styling
    link_to(link_params, class: secondary_sort_link_classes(is_active)) do
      label
    end
  end
  
  # Generate the CSS classes for a primary sort link
  # @param is_active [Boolean] Whether this is the active sort
  # @return [String] CSS classes
  def sort_link_classes(is_active)
    base_classes = "px-3 py-1 text-sm rounded-md transition-colors duration-150"
    
    if is_active
      "#{base_classes} bg-indigo-100 text-indigo-700 font-medium"
    else
      "#{base_classes} bg-gray-100 text-gray-700 hover:bg-gray-200"
    end
  end
  
  # Generate the CSS classes for a secondary sort link
  # @param is_active [Boolean] Whether this is the active secondary sort
  # @return [String] CSS classes
  def secondary_sort_link_classes(is_active)
    base_classes = "px-2 py-1 text-xs rounded-md transition-colors duration-150"
    
    if is_active
      "#{base_classes} bg-orange-50 text-orange-600 font-medium"
    else
      "#{base_classes} bg-gray-50 text-gray-600 hover:bg-gray-100"
    end
  end
end
