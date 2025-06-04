module TeamsHelper
  # Generates a link to start a quiz for a given resource
  # @param resource [Object] The resource to generate the quiz link for
  # @param options [Hash] Additional HTML options for the link
  # @return [String] HTML link to start the quiz
  def quiz_link(resource, options = {})
    return unless resource.present?

    resource_type = resource.class.name.underscore
    default_options = {
      class: "quiz-button for-#{resource_type}",
      id: dom_id(resource, :quiz_link_for),
      data: { turbo: false }
    }

    # Use a named route for team_match, dynamically setting the query parameter based on resource type
    link_to 'Quiz Me', strength_team_match_path(:"#{resource_type}_id" => resource.id), 
           default_options.merge(options)
  end
  
  # Formats a team name for display
  # @param team [Team] The team to format name for
  # @return [String] Formatted team name
  def formatted_team_name(team)
    if team.territory.present? && team.mascot.present?
      "#{team.territory} #{team.mascot}"
    elsif team.territory.present?
      team.territory
    elsif team.mascot.present?
      team.mascot
    else
      "Unknown Team"
    end
  end
  
  # Formats a full team location with city and state
  # @param team [Team] The team to format location for
  # @return [String] Formatted team location
  def formatted_team_location(team)
    return "Unknown Location" unless team.stadium&.city
    
    "#{team.stadium.city.name}, #{team.stadium.city.state.abbreviation}"
  end
  
  # Helper for creating auto-submitting select dropdowns
  # @param form [ActionView::Helpers::FormBuilder] The form builder
  # @param attribute [Symbol] The attribute to search on
  # @param collection [Array] Collection of items for the dropdown
  # @param label_text [String] Label for the field
  # @param include_blank [Boolean] Whether to include a blank option
  # @param blank_text [String] Text for the blank option
  # @return [String] HTML for the select dropdown
  def auto_submit_select(form, attribute, collection, label_text, include_blank: true, blank_text: nil)
    blank_text ||= "-- Select #{label_text} --"
    
    select_options = include_blank ? [[blank_text, nil]] : []
    select_options += collection
    
    tag.div do
      form.label(attribute, label_text, class: "form-field-label") +
      form.select(attribute, 
                select_options, 
                {}, 
                { class: "form-field-input", 
                  onchange: "this.form.submit();" })
    end
  end

  # Creates a search form for teams with filters
  # @param search [Ransack::Search] The Ransack search object
  # @return [String] HTML for the teams search form
  def team_search_form(search)
    # Return an error message if search is nil
    return tag.div("No search object available", class: "search-unavailable") if search.nil?
    
    # Create the search form
    search_form_for search, url: teams_path, html: { class: "search-form" } do |f|
      tag.div class: "search-form-container" do
        content = []
        
        # Search form title
        content << tag.h3("Filter Teams", class: "search-form-title mb-4")
        
        # Basic search fields
        content << tag.div(class: "basic-filters grid grid-cols-1 md:grid-cols-3 gap-4 mb-6") do
          basic_fields = []
          
          # Team name search field
          basic_fields << tag.div do
            f.label(:territory_or_mascot_cont, "Name contains", class: "form-field-label block mb-1") +
            f.search_field(:territory_or_mascot_cont, class: "form-field-input w-full p-2 border rounded")
          end
          
          # City search field
          basic_fields << tag.div do
            f.label(:stadium_city_name_cont, "City", class: "form-field-label block mb-1") +
            f.search_field(:stadium_city_name_cont, class: "form-field-input w-full p-2 border rounded")
          end
          
          # League search field
          basic_fields << tag.div do
            f.label(:league_name_cont, "League", class: "form-field-label block mb-1") +
            f.search_field(:league_name_cont, class: "form-field-input w-full p-2 border rounded")
          end
          
          safe_join basic_fields
        end
        
        # Advanced filters section (collapsible)
        content << tag.div(class: "advanced-filters-container", data: { controller: "collapse" }) do
          toggle = tag.div(class: "advanced-filters-toggle cursor-pointer flex items-center text-blue-600 mb-3", 
                         data: { action: "click->collapse#toggle" }) do
            tag.span("Advanced Filters", class: "mr-2") +
            tag.i(class: "#{icon_for_resource :chevron_down}")
          end
          
          adv_content = tag.div(class: "advanced-filters-content hidden", data: { collapse_target: "content" }) do
            adv_fields = []
            
            # Only add filters if filter_options are available
            if defined?(@filter_options) && @filter_options.present?
              adv_grid = tag.div(class: "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4") do
                grid_fields = []
                
                # Sport filter
                if @filter_options[:sports].present?
                  sports = @filter_options[:sports].map { |s| [s.name, s.id] }
                  grid_fields << auto_submit_select(f, :league_sport_id_eq, sports, "Sport")
                end
                
                # League filter
                if @filter_options[:leagues].present?
                  leagues = @filter_options[:leagues].map { |l| [l.name, l.id] }
                  grid_fields << auto_submit_select(f, :league_id_eq, leagues, "League")
                end  
                # Conference filter
                if @filter_options[:conferences].present?
                  conferences = @filter_options[:conferences].map { |c| [c.name, c.id] }
                  grid_fields << auto_submit_select(f, :conference_id_eq, conferences, "Conference")
                end
                # Division filter
                if @filter_options[:divisions].present?
                  divisions = @filter_options[:divisions].map { |d| [d.name, d.id] }
                  grid_fields << auto_submit_select(f, :division_id_eq, divisions, "Division")
                end
                # State filter
                if @filter_options[:states].present?
                  states = @filter_options[:states].map { |s| [s.name, s.id] }
                  grid_fields << auto_submit_select(f, :stadium_city_state_id_eq, states, "State")
                end
                # City filter
                if @filter_options[:cities].present?
                  cities = @filter_options[:cities].map { |c| [c.name, c.id] }
                  grid_fields << auto_submit_select(f, :stadium_city_id_eq, cities, "City")
                end
                # Stadium filter
                if @filter_options[:stadiums].present?
                  stadiums = @filter_options[:stadiums].map { |s| [s.name, s.id] }
                  grid_fields << auto_submit_select(f, :stadium_id_eq, stadiums, "Stadium")
                end
                
                safe_join grid_fields
              end
              adv_fields << adv_grid
            else
              adv_fields << tag.div("No advanced filter options available", class: "text-gray-500 italic")
            end
            safe_join adv_fields
          end
          toggle + adv_content
        end
        
        # Form actions
        content << tag.div(class: "form-actions mt-4") do
          reset_btn = link_to "Reset", teams_path, class: "px-4 py-2 border border-gray-300 rounded text-gray-700 mr-2"
          submit_btn = f.submit "Apply Filters", class: "px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 cursor-pointer"
          reset_btn + submit_btn
        end
        safe_join content
      end
    end
  end
end
