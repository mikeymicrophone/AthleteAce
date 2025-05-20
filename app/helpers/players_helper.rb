module PlayersHelper
  # Renders sorting options for players with active state indication
  # @param players [ActiveRecord::Relation] The players collection
  # @return [String] HTML for the sorting options
  def sorting_scopes_for(players)
    current_sort = params[:sort] || "first_name"
    
    tag.div(class: "flex justify-end") do
      tag.div(class: "flex flex-wrap gap-2 items-center") do
        # Label
        tag.span("Sort by:", class: "text-sm text-gray-600 mr-1") +
        
        # Sort options
        sort_link("First Name", "first_name", current_sort) +
        sort_link("Last Name", "last_name", current_sort) +
        sort_link("Team", "team_id", current_sort) +
        sort_link("League", "league_id", current_sort) +
        sort_link("Sport", "sport_id", current_sort) +
        sort_link("Random", "random", current_sort, icon: "fa-solid fa-shuffle")
      end
    end
  end
  
  # Helper to create a consistent sort link with active state
  # @param label [String] The link text
  # @param sort_param [String] The sort parameter value
  # @param current_sort [String] The current sort parameter
  # @param icon [String] Optional Font Awesome icon class
  # @return [String] HTML for the sort link
  def sort_link(label, sort_param, current_sort, icon: nil)
    is_active = current_sort == sort_param
    
    # Preserve all existing params except page (we'll reset to page 1)
    link_params = request.params.except(:page).merge(sort: sort_param)
    
    # Generate the link with appropriate styling
    link_to(link_params, class: sort_link_classes(is_active)) do
      if icon.present?
        tag.i(class: "#{icon} mr-1") + label
      else
        label
      end
    end
  end
  
  # Generate the CSS classes for a sort link
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
end
