module TeamsHelper
  # Generates a link to start a team quiz
  # @param team [Team] The team to generate the quiz link for
  # @param options [Hash] Additional HTML options for the link
  # @return [String] HTML link to start the team quiz
  def team_quiz_link(team, options = {})
    return unless team.present?
    
    default_options = {
      class: 'inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500',
      data: { turbo: false }
    }
    
    # Use the direct path since we don't have a named route for team_match with team_id
    link_to 'Quiz Me', "/strength/team_match?team_id=#{team.id}", 
           default_options.merge(options)
  end

  # Helper to create a search form for teams
  # @param search [Ransack::Search] The Ransack search object
  # @return [String] HTML for the search form
  def team_search_form search
    # Handle nil search object gracefully
    return tag.div(class: "search-form-container") { tag.p "Search is unavailable" } unless search
    
    search_form_for search, class: "search-form" do |f|
      tag.div class: "search-form-container" do
        content = []
        content << tag.h3("Filter Teams", class: "search-form-title")
        
        # Basic search fields
        content << tag.div(class: "search-fields-grid") do
          fields = []
          
          # Team name search fields (territory and mascot)
          fields << tag.div do
            f.label(:territory_or_mascot_cont, "Name contains", class: "form-field-label") +
            f.search_field(:territory_or_mascot_cont, class: "form-field-input")
          end
          
          # City search field (from stadium)
          fields << tag.div do
            f.label(:stadium_city_cont, "City", class: "form-field-label") +
            f.search_field(:stadium_city_cont, class: "form-field-input")
          end
          
          # League search field
          fields << tag.div do
            f.label(:league_name_cont, "League", class: "form-field-label") +
            f.search_field(:league_name_cont, class: "form-field-input")
          end
          
          safe_join fields
        end
        
        # Advanced search section (collapsible)
        content << tag.div(class: "advanced-filters-container", data: { controller: "collapse" }) do
          toggle = tag.div(class: "advanced-filters-toggle", data: { action: "click->collapse#toggle" }) do
            tag.span("Advanced Filters", class: "advanced-filters-text") +
            tag.i(class: "advanced-filters-icon #{icon_for_resource :chevron_down}")
          end
          
          advanced_content = tag.div(class: "advanced-filters-content", data: { collapse_target: "content" }) do
            adv_fields = []
            
            # Sport search field (through league)
            adv_fields << tag.div do
              f.label(:league_sport_name_cont, "Sport", class: "form-field-label") +
              f.search_field(:league_sport_name_cont, class: "form-field-input")
            end
            
            # Division search field
            adv_fields << tag.div do
              f.label(:division_name_cont, "Division", class: "form-field-label") +
              f.search_field(:division_name_cont, class: "form-field-input")
            end
            
            # Conference search field
            adv_fields << tag.div do
              f.label(:conference_name_cont, "Conference", class: "form-field-label") +
              f.search_field(:conference_name_cont, class: "form-field-input")
            end
            
            safe_join adv_fields
          end
          
          toggle + advanced_content
        end
        
        # Form actions
        content << tag.div(class: "form-actions") do
          reset = link_to "Reset", teams_path, class: "reset-button"
          
          submit = button_tag type: "submit", class: "submit-button" do
            tag.span do
              tag.i(class: "search-icon #{icon_for_resource :search}") + 
              tag.span("Search", class: "ml-1")
            end
          end
          
          reset + submit
        end
        
        safe_join content
      end
    end
  end
end
