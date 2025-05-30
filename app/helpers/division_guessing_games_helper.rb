module DivisionGuessingGamesHelper
  # Container for the division guessing game with data attributes for the Stimulus controller
  def division_game_container(team, correct_division, choices, &block)
    tag.div id: "division_game_container", class: "division-game-container", data: { 
      controller: "division-game",
      division_game_team_id_value: team.id,
      division_game_correct_division_id_value: correct_division.id
    } do
      capture(&block)
    end
  end
  
  # Display attempts history container
  def division_attempts_history_container
    tag.div id: "division_attempts", 
            class: "attempts-container mt-8 p-4 border border-gray-200 rounded-lg shadow-sm", 
            data: { division_game_target: "attemptsContainer" } do
      tag.h3("Recent Attempts", id: "division_attempts_heading", class: "attempts-heading text-lg font-semibold mb-3 text-center text-gray-700") +
      tag.div(id: "division_attempts_grid", 
              class: "attempts-grid grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4", 
              data: { division_game_target: "attemptsGrid" }) +
      division_attempt_card_template
    end
  end
  
  # Template for division attempt cards
  def division_attempt_card_template
    tag.div id: "division-attempt-template", class: "attempt-template hidden" do
      # The correct-attempt or incorrect-attempt class will be added dynamically by JavaScript
      tag.div id: "division-attempt-card", class: "attempt-card flex flex-col items-center border rounded-md overflow-hidden" do
        # Team part
        tag.div(id: "team-part", class: "attempt-team-part w-full p-2 text-center") do
          tag.div(id: "team-logo-container", class: "attempt-team-logo-container flex justify-center items-center h-16") do
            tag.img(id: "team-logo", class: "attempt-team-logo max-h-16 max-w-full object-contain", src: "", alt: "Team Logo")
          end +
          tag.p(id: "team-name", class: "attempt-team-name text-sm font-semibold mt-1 truncate w-full")
        end +
        # Division part
        tag.div(id: "division-part", class: "attempt-division-part w-full p-2 text-center border-t") do
          tag.div(id: "division-icon-container", class: "attempt-division-icon-container flex justify-center items-center h-12") do
            tag.i(id: "division-icon", class: "fas fa-shield-alt text-2xl")
          end +
          tag.p(id: "division-name", class: "attempt-division-name text-xs font-medium mt-1 truncate w-full")
        end
      end
    end
  end
  
  # Render team card with logo and information
  def team_card(team)
    tag.div class: "team-card bg-white rounded-lg shadow-md p-6" do
      team_logo_container(team) + team_info(team)
    end
  end

  # Render team logo container
  def team_logo_container(team)
    tag.div class: "team-logo-container flex justify-center items-center h-32 mb-4" do
      if team.logo_url.present?
        tag.img src: team.logo_url, alt: "#{team.name} logo", class: "max-h-32 max-w-full object-contain"
      else
        tag.div class: "h-32 w-32 flex items-center justify-center bg-gray-200 rounded-full" do
          tag.i class: "fas fa-shield-alt text-6xl text-gray-400"
        end
      end
    end
  end

  # Render team information
  def team_info(team)
    tag.div class: "team-info text-center" do
      tag.h2(team.name, class: "team-name text-2xl font-bold mb-2") +
        (team.league.present? ? tag.p(team.league.name, class: "team-league text-gray-600") : "")
    end
  end

  # Render division choices grid
  def division_choices_grid(choices, correct_division)
    tag.div class: "grid grid-cols-2 gap-4" do
      choices.map do |division|
        tag.button class: "division-choice #{division == correct_division ? 'correct-choice' : 'incorrect-choice'} flex flex-col items-center justify-center w-full h-32 p-4 rounded-lg shadow-md transition-colors duration-200",
                   data: {
                     division_guess_target: "divisionChoice",
                     division_id: division.id,
                     correct: (division == correct_division).to_s,
                     action: "click->division-guess#checkAnswer"
                   } do
          tag.span division.name, class: "division-name text-lg font-medium text-center"
        end
      end.join.html_safe
    end
  end
  
  # Render a recent attempts section
  def recent_division_attempts(ace, limit = 5)
    attempts = ace.game_attempts.where(game_type: "guess_the_division").order(created_at: :desc).limit(limit)
    
    return nil if attempts.empty?
    
    tag.div class: "recent-attempts mt-6" do
      tag.h3("Your Recent Attempts", class: "text-lg font-semibold mb-3") +
      tag.div(class: "grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4") do
        attempts.map do |attempt|
          render_division_attempt_card(attempt)
        end.join.html_safe
      end
    end
  end
  
  # Render a single attempt card
  def render_division_attempt_card(attempt)
    team = attempt.subject_entity
    correct_division = attempt.target_entity
    chosen_division = attempt.chosen_entity
    
    tag.div class: "attempt-card border rounded-lg overflow-hidden #{attempt.correct? ? 'border-green-500' : 'border-red-500'}" do
      tag.div(class: "p-3 #{attempt.correct? ? 'bg-green-50' : 'bg-red-50'}") do
        tag.div(class: "flex items-center mb-2") do
          if team.logo_url.present?
            tag.img(src: team.logo_url, alt: team.name, class: "h-8 w-8 mr-2 object-contain")
          else
            tag.div(class: "h-8 w-8 mr-2 flex items-center justify-center bg-gray-200 rounded-full") do
              tag.i(class: "fas fa-shield-alt text-gray-500")
            end
          end +
          tag.div(team.name, class: "font-medium text-sm")
        end +
        tag.div(class: "text-xs text-gray-600 mb-1") do
          "Your guess: #{chosen_division.name}"
        end +
        tag.div(class: "text-xs #{attempt.correct? ? 'text-green-600' : 'text-red-600'}") do
          if attempt.correct?
            "Correct!"
          else
            "Correct answer: #{correct_division.name}"
          end
        end
      end +
      tag.div(class: "text-xs p-2 bg-gray-50 text-gray-500 text-right") do
        time_ago_in_words(attempt.created_at) + " ago"
      end
    end
  end
end
