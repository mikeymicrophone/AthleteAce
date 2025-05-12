module StrengthHelper

  def player_card player
    tag.div class: "player-info mb-6 text-center" do
      tag.h2("Who does #{player.full_name} play for?", class: "text-2xl font-bold mb-2") +
      tag.div(class: "player-card bg-white rounded-lg shadow-lg p-4 max-w-md mx-auto flex flex-col") do
        if player.photo_urls.present?
          tag.div class: "player-image-container h-64 mb-4 w-full" do
            tag.img src: player.photo_urls.first, alt: player.full_name, class: "h-full mx-auto object-contain"
          end
        else
          tag.div class: "player-image-placeholder h-64 mb-4 bg-gray-200 flex items-center justify-center w-full" do
            tag.i class: "fa-solid fa-user text-6xl text-gray-400"
          end
        end +
        tag.div(class: "player-text-container mt-4 text-center w-full") do
          tag.h3(player.full_name, class: "text-xl font-bold") + 
          (player.primary_position ? tag.p(player.primary_position.name, class: "text-gray-600") : '')
        end
      end
    end
  end

  def team_choice_group teams, correct_team_id
    tag.div class: "team-choices-container max-w-2xl mx-auto" do
      tag.div class: "team-choices-grid grid grid-cols-2 gap-6", data: {team_match_target: "choicesGrid"} do
        teams.map do |team|
          team_choice_button team, team.id == correct_team_id
        end.join.html_safe
      end
    end
  end

  def team_choice_button team, correct = false
    tag.button class: "team-choice bg-white rounded-lg shadow-md p-4 flex flex-col items-center justify-center transition-all duration-300 hover:shadow-lg w-full h-48",
      data: {
        team_match_target: "teamChoice",
        team_id: team.id,
        correct: correct,
        action: "click->team-match#checkAnswer"
      } do
      tag.div(class: "team-logo-container h-20 w-20 mb-3 flex items-center justify-center") do
        if team.logo_url.present?
          tag.img src: team.logo_url, alt: "#{team.name} logo", class: "max-h-full max-w-full object-contain"
        else
          tag.div class: "team-logo-placeholder h-full w-full bg-gray-200 flex items-center justify-center rounded-full" do
            tag.i class: "fa-solid fa-shield-alt text-4xl text-gray-400"
          end
        end
      end +
      tag.span("#{team.territory} #{team.mascot}", class: "team-name text-lg font-medium text-center")
    end
  end

  def pause_button stimulus_controller = "team-match"
    tag.div class: "pause-button" do
      tag.button(
        tag.i(class: 'fa-solid fa-pause mr-2') + 
        tag.span('Pause', data: { "#{stimulus_controller}_target": "pauseButtonText" }),
        class: "flex items-center bg-gray-200 hover:bg-gray-300 font-medium py-2 px-4 rounded-lg transition-colors duration-200",
        data: {
          "#{stimulus_controller}_target": "pauseButton",
          action: "click->#{stimulus_controller}#togglePause"
        }
      )
    end
  end

  def teams_filter_label parent
    tag.div class: "filter-indicator" do
      tag.div class: "filter-badge" do
        tag.span("#{parent.class.name}:", class: "filter-label") +
        tag.span(parent.name, class: "filter-value")
      end
    end if parent
  end

end
