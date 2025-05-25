module StrengthHelper

  def player_card(player)
    tag.div id: dom_id(player, 'info'), class: "player-info mb-6 text-center" do
      tag.h2("Who does #{player.full_name} play for?", class: "player-question text-2xl font-bold mb-2") +
      tag.div(id: dom_id(player, 'card'), class: "player-card bg-white rounded-lg shadow-lg p-4 max-w-md mx-auto flex flex-col") do
        if player.photo_urls.present?
          tag.div id: dom_id(player, 'image_container'), class: "player-image-container h-64 mb-4 w-full" do
            tag.img src: player.photo_urls.first, alt: player.full_name, class: "player-photo h-full mx-auto object-contain"
          end
        else
          tag.div id: dom_id(player, 'image_placeholder'), class: "player-image-placeholder h-64 mb-4 bg-gray-200 flex items-center justify-center w-full" do
            tag.i class: "fa-solid fa-user text-6xl text-gray-400"
          end
        end +
        tag.div(id: dom_id(player, 'text_container'), class: "player-text-container mt-4 text-center w-full") do
          tag.h3(player.full_name, id: dom_id(player, 'name'), data: { player_name: true }, class: "player-name text-xl font-bold") + 
          (player.primary_position ? tag.p(player.primary_position.name, id: dom_id(player, 'position'), class: "player-position text-gray-600") : '')
        end
      end
    end
  end

  def team_choice_group(teams, correct_team_id)
    tag.div id: "team_choices_container", class: "team-choices-container max-w-2xl mx-auto" do
      tag.div id: "team_choices_grid", class: "team-choices-grid grid grid-cols-2 gap-6", data: {team_match_target: "choicesGrid"} do
        teams.map do |team|
          team_choice_button team, team.id == correct_team_id
        end.join.html_safe
      end
    end
  end

  def team_choice_button(team, correct = false)
    tag.button id: dom_id(team, 'choice'), 
      class: "team-choice bg-white rounded-lg shadow-md p-4 flex flex-col items-center justify-center transition-all duration-300 hover:shadow-lg w-full h-48",
      data: {
        team_match_target: "teamChoice",
        team_id: team.id,
        correct: correct,
        team_logo_url: team.logo_url,
        action: "click->team-match#checkAnswer"
      } do
      tag.div(id: dom_id(team, 'logo_container'), class: "team-logo-container h-20 w-20 mb-3 flex items-center justify-center") do
        if team.logo_url.present?
          tag.img src: team.logo_url, alt: "#{team.name} logo", id: dom_id(team, 'logo'), class: "team-logo max-h-full max-w-full object-contain"
        else
          tag.div id: dom_id(team, 'logo_placeholder'), class: "team-logo-placeholder h-full w-full bg-gray-200 flex items-center justify-center rounded-full" do
            tag.i class: "fa-solid fa-shield-alt text-4xl text-gray-400"
          end
        end
      end +
      tag.span("#{team.territory} #{team.mascot}", id: dom_id(team, 'name'), class: "team-name text-lg font-medium text-center")
    end
  end

  def pause_button(stimulus_controller = "team-match")
    tag.div id: "pause_button_container", class: "pause-button-container" do
      tag.button(
        tag.i(class: 'fa-solid fa-pause mr-2') + 
        tag.span('Pause', id: "pause_button_text", data: { "#{stimulus_controller}_target": "pauseButtonText" }),
        id: "pause_button",
        class: "pause-button flex items-center bg-gray-200 hover:bg-gray-300 font-medium py-2 px-4 rounded-lg transition-colors duration-200",
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
  
  # New helper methods for team_match template
  
  def game_container(player, correct_team, team_choices, parent, &block)
    tag.div id: "team_match_container", class: "team-match-container", data: { 
      controller: "team-match",
      team_match_player_id_value: player.id,
      team_match_correct_team_id_value: correct_team.id
    } do
      tag.div(teams_filter_label(parent), id: "filter_indicators", class: "filter-indicators mb-4") +
      capture(&block)
    end
  end

  def game_layout(&block)
    tag.div id: "game_layout", class: "game-layout flex flex-col lg:flex-row lg:gap-x-8" do
      capture(&block)
    end
  end

  def player_card_section(player)
    tag.div id: "player_card_area", class: "player-card-area lg:w-1/3 mb-4 lg:mb-0" do
      tag.div id: "current_player_card_display", 
              class: "current-player-card mb-4", 
              data: { 
                team_match_target: "currentPlayerCardDisplay",
                player_id: player.id,
                player_team_id: player.team_id
              } do
        player_card(player)
      end
    end
  end

  def team_choices_section(team_choices, correct_team_id)
    tag.div id: "team_choices_section", class: "team-choices-section lg:w-2/3" do
      tag.div id: "team_match_game_container", class: "team-match-game-container" do
        tag.div(team_choice_group(team_choices, correct_team_id), 
                id: "team_match_game", 
                class: "team-match-game", 
                data: { team_match_target: "gameContainer" }) +
        team_name_overlay +
        tag.div(pause_button("team-match"), 
                id: "controls", 
                class: "controls flex justify-between items-center mt-8", 
                data: { team_match_target: "controls" })
      end
    end
  end

  def team_name_overlay
    tag.div id: "team_name_overlay", 
            class: "team-name-overlay fixed inset-0 flex items-center justify-center pointer-events-none opacity-0 z-50", 
            data: { team_match_target: "teamNameOverlay" } do
      tag.div id: "team_name_content", 
              class: "team-name-content text-8xl font-extrabold text-center text-white text-shadow-lg" do
        tag.span id: "team_name_text", class: "team-name-text", data: { team_match_target: "teamNameText" }
      end
    end
  end

  def progress_indicator
    tag.div id: "progress", class: "progress-indicator" do
      tag.span "Progress: #{tag.span("0", id: "progress_counter", class: "progress-counter", data: { team_match_target: "progressCounter" })} correct".html_safe, 
               class: "progress-text text-gray-600"
    end
  end

  def attempts_history_container
    tag.div id: "attempts", 
            class: "attempts-container mt-8 p-4 border border-gray-200 rounded-lg shadow-sm hidden", 
            data: { team_match_target: "attemptsContainer" } do
      tag.h3("Recent Attempts", id: "attempts_heading", class: "attempts-heading text-lg font-semibold mb-3 text-center text-gray-700") +
      tag.div(id: "attempts_grid", 
              class: "attempts-grid grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4", 
              data: { team_match_target: "attemptsGrid" }) +
      attempt_card_template
    end
  end

  def attempt_card_template
    tag.div id: "attempt-template", class: "attempt-template hidden" do
      tag.div id: "attempt-card", class: "attempt-card flex flex-col items-center border rounded-md overflow-hidden" do
        # Team part
        tag.div(id: "team-part", class: "attempt-team-part w-full p-2 text-center") do
          tag.div(id: "team-logo-container", class: "attempt-team-logo-container flex justify-center items-center h-16") do
            tag.img(id: "team-logo", class: "attempt-team-logo max-h-16 max-w-full object-contain", src: "", alt: "Team Logo")
          end +
          tag.p(id: "team-name", class: "attempt-team-name text-sm font-semibold mt-1 truncate w-full")
        end +
        # Player part
        tag.div(id: "player-part", class: "attempt-player-part w-full p-2 text-center border-t") do
          tag.div(id: "player-photo-container", class: "attempt-player-photo-container flex justify-center items-center h-12") do
            tag.img(id: "player-photo", class: "attempt-player-photo max-h-12 max-w-full object-contain", src: "", alt: "Player Photo")
          end +
          tag.p(id: "player-name", class: "attempt-player-name text-xs font-medium mt-1 truncate w-full")
        end
      end
    end
  end
end
