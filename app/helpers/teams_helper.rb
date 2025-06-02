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
  # Helper to create an auto-submitting select dropdown for search forms
  # @param form [ActionView::Helpers::FormBuilder] The form builder object
  # @param attribute [Symbol] The model attribute to search on
  # @param collection [Array] Array of options as [name, id] pairs
  # @param label_text [String] Text for the field label
  # @param include_blank [Boolean] Whether to include a blank option
  # @param blank_text [String] Text for the blank option
  # @return [String] HTML for the select dropdown
  def auto_submit_select(form, attribute, collection, label_text, include_blank: true, blank_text: nil)
    blank_text ||= "-- Select #{label_text} --"
    
    if include_blank
      collection = [[blank_text, nil]] + collection
    end
    
    tag.div do
      form.label(attribute, label_text, class: "form-field-label") +
      form.select(attribute, 
                collection, 
                {}, 
                { class: "form-field-input", 
                  onchange: "this.form.submit();" })
    end
  end

  def team_search_form(search)
    # If search is nil, display a message and return
    return tag.div "No search object available", class: "search-unavailable" if search.nil?
    
    search_form_for search, class: "search-form", html: { data: { controller: "autosubmit" } } do |f|
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
          
          # City search field (from stadium's city)
          fields << tag.div do
            f.label(:stadium_city_name_cont, "City", class: "form-field-label") +
            f.search_field(:stadium_city_name_cont, class: "form-field-input")
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
            
            # Sport select dropdown
            sports = Sport.all.map { |s| [s.name, s.id] }
            adv_fields << auto_submit_select(f, :league_sport_id_eq, sports, "Sport")
            
            # League select dropdown
            leagues = League.all.map { |l| [l.name, l.id] }
            adv_fields << auto_submit_select(f, :league_id_eq, leagues, "League")
            
            # Division select dropdown
            divisions = Division.all.map { |d| [d.name, d.id] }
            adv_fields << auto_submit_select(f, :division_id_eq, divisions, "Division")
            
            # Conference select dropdown
            conferences = Conference.all.map { |c| [c.name, c.id] }
            adv_fields << auto_submit_select(f, :conference_id_eq, conferences, "Conference")
            
            # State select dropdown
            states = State.all.map { |s| [s.name, s.id] }
            adv_fields << auto_submit_select(f, :stadium_city_state_id_eq, states, "State")
            
            # City select dropdown
            cities = City.all.map { |c| [c.name, c.id] }
            adv_fields << auto_submit_select(f, :stadium_city_id_eq, cities, "City")
            
            # Stadium select dropdown
            stadiums = Stadium.all.map { |s| [s.name, s.id] }
            adv_fields << auto_submit_select(f, :stadium_id_eq, stadiums, "Stadium")
            
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
