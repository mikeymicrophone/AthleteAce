module DivisionGuessingGamesHelper
  # Container for the division guessing game with data attributes for the Stimulus controller
  # def division_game_container(team, correct_division, choices, &block)
  #   tag.div id: "division_game_container", class: "division-game-container", data: { 
  #     controller: "division-game",
  #     division_game_team_id_value: team.id,
  #     division_game_correct_division_id_value: correct_division.id
  #   } do
  #     capture(&block)
  #   end
  # end
  
  # # Display attempts history container
  # def division_attempts_history_container
  #   tag.div id: "division_attempts", class: "attempts-container", data: { division_game_target: "attemptsContainer" } do
  #     tag.h3("Recent Attempts", id: "division_attempts_heading", class: "attempts-heading") +
  #     tag.div(id: "division_attempts_grid", class: "attempts-grid", data: { division_game_target: "attemptsGrid" }) +
  #     division_attempt_card_template
  #   end
  # end
  
  # # Template for division attempt cards
  # def division_attempt_card_template
  #   tag.div id: "division-attempt-template", class: "attempt-template hidden" do
  #     # The correct-attempt or incorrect-attempt class will be added dynamically by JavaScript
  #     tag.div id: "division-attempt-card", class: "attempt-card" do
  #       # Team part
  #       tag.div(id: "team-part", class: "attempt-team-part") do
  #         tag.div(id: "team-logo-container", class: "attempt-team-logo-container") do
  #           tag.img(id: "team-logo", class: "attempt-team-logo", src: "", alt: "Team Logo")
  #         end +
  #         tag.p(id: "team-name", class: "attempt-team-name")
  #       end +
  #       # Division part
  #       tag.div(id: "division-part", class: "attempt-division-part") do
  #         tag.div(id: "division-icon-container", class: "attempt-division-icon-container") do
  #           tag.i(id: "division-icon", class: "fas fa-shield-alt attempt-division-icon")
  #         end +
  #         tag.p(id: "division-name", class: "attempt-division-name")
  #       end
  #     end
  #   end
  # end
  
  # # Render team card with logo and information
  # def team_card(team, data_attributes = {})
  #   tag.div class: "team-card", data: data_attributes do
  #     team_logo_container(team) + team_info(team)
  #   end
  # end

  # # Render team logo container
  # def team_logo_container(team)
  #   tag.div class: "team-logo-container" do
  #     if team.logo_url.present?
  #       tag.img src: team.logo_url, alt: "#{team.name} logo", class: "team-logo"
  #     else
  #       tag.div class: "team-logo-placeholder" do
  #         tag.i class: "fas fa-shield-alt team-logo-placeholder-icon"
  #       end
  #     end
  #   end
  # end

  # # Render team information
  # def team_info(team)
  #   tag.div class: "team-info" do
  #     tag.h2(team.name, class: "team-name") +
  #       (team.league.present? ? tag.p(team.league.name, class: "team-league") : "")
  #   end
  # end

  # # Render division choices grid
  # def division_choices_grid(choices, correct_division)
  #   tag.div class: "division-choices-grid" do
  #     choices.map do |division|
  #       tag.button class: "division-choice #{division == correct_division ? 'correct-choice' : 'incorrect-choice'}",
  #                  data: {
  #                    division_guess_target: "divisionChoice",
  #                    division_id: division.id,
  #                    correct: (division == correct_division).to_s,
  #                    action: "click->division-guess#checkAnswer"
  #                  } do
  #         tag.div(class: "division-choice-content") do
  #           tag.div class: "division-icon-wrapper" do
  #             tag.i class: "fas fa-shield-alt division-choice-icon"
  #           end
  #         end + tag.span(division.name, class: "division-name")
  #       end
  #     end.join.html_safe
  #   end
  # end
  
  # # Render a recent attempts section
  # def recent_division_attempts(ace, limit = 5)
  #   attempts = ace.game_attempts.where(game_type: "guess_the_division").order(created_at: :desc).limit(limit)
    
  #   return nil if attempts.empty?
    
  #   tag.div class: "recent-attempts" do
  #     tag.h3("Your Recent Attempts", class: "recent-attempts-heading") +
  #     tag.div(class: "recent-attempts-grid") do
  #       attempts.map do |attempt|
  #         render_division_attempt_card(attempt)
  #       end.join.html_safe
  #     end
  #   end
  # end
  
  # # Render a single attempt card
  # def render_division_attempt_card(attempt)
  #   team = attempt.subject_entity
  #   correct_division = attempt.target_entity
  #   chosen_division = attempt.chosen_entity
    
  #   tag.div class: "recent-attempt-card #{attempt.correct? ? 'correct-attempt' : 'incorrect-attempt'}" do
  #     tag.div(class: "recent-attempt-content") do
  #       tag.div(class: "recent-attempt-team") do
  #         if team.logo_url.present?
  #           tag.img(src: team.logo_url, alt: team.name, class: "recent-attempt-team-logo")
  #         else
  #           tag.div(class: "recent-attempt-team-logo-placeholder") do
  #             tag.i(class: "fas fa-shield-alt recent-attempt-team-logo-icon")
  #           end
  #         end +
  #         tag.div(team.name, class: "recent-attempt-team-name")
  #       end +
  #       tag.div(class: "recent-attempt-guess") do
  #         "Your guess: #{chosen_division.name}"
  #       end +
  #       tag.div(class: "recent-attempt-result") do
  #         if attempt.correct?
  #           "Correct!"
  #         else
  #           "Correct answer: #{correct_division.name}"
  #         end
  #       end
  #     end +
  #     tag.div(class: "recent-attempt-timestamp") do
  #       time_ago_in_words(attempt.created_at) + " ago"
  #     end
  #   end
  # end
end
