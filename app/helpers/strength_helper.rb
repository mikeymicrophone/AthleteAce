module StrengthHelper

  def player_card player
    tag.div class: "player-info mb-6 text-center" do
      tag.h2("Who does #{player.full_name} play for?", class: "text-2xl font-bold mb-2") +
      tag.div(class: "player-card bg-white rounded-lg shadow-lg p-4 max-w-md mx-auto") do
        if player.photo_urls.present?
          tag.div class: "player-image-container h-64 mb-4" do
            tag.img src: player.photo_urls.first, alt: player.full_name, class: "h-full mx-auto object-contain"
          end
        else
          tag.div class: "player-image-placeholder h-64 mb-4 bg-gray-200 flex items-center justify-center" do
            tag.i class: "fa-solid fa-user text-6xl text-gray-400"
          end
        end +
        tag.h3(player.full_name, class: "text-xl font-bold") + 
        (player.primary_position ? tag.p(player.primary_position.name, class: "text-gray-600") : '')
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
      tag.button "<i class='fa-solid fa-pause mr-2'></i> Pause".html_safe,
        class: "bg-gray-200 hover:bg-gray-300 text-gray-800 font-medium py-2 px-4 rounded-lg transition-colors duration-200",
        data: {
          (stimulus_controller.underscore + "_target") => "pauseButton",
          action: "click->#{stimulus_controller}#togglePause"
        }
    end
  end
end
