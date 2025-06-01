module ReviewHelper
  def team_attempts_filter_button team
    link_to team_strength_game_attempts_path(team), class: "team-button" do
      tag.div class: "team-button-content" do
        if team.logo_url.present?
          tag.img src: team.logo_url, alt: "#{team.name} logo", class: "team-button-logo"
        else
          tag.i class: "fa-solid fa-shield-alt team-button-icon"
        end +
        tag.span(team.name, class: "team-button-name") +
        tag.span("#{@team_stats[team][:correct_attempts]}/#{@team_stats[team][:total_attempts]}", class: "team-button-stats")
      end
    end
  end

  def sport_group_team_buttons sport, teams_by_sport
    tag.div class: "sport-section" do
      tag.h3(sport.name, class: "sport-title") +
      tag.div(class: "teams-buttons") do
        safe_join teams_by_sport[sport].map { |team| team_attempts_filter_button(team) }
      end
    end
  end

  def team_attempts_filter_panel teams_by_sport, sports
    tag.div class: "teams-navigation" do
      tag.h2 "Teams by Sport", class: "teams-navigation-title"
      safe_join sports.map { |sport| sport_group_team_buttons(sport, teams_by_sport) }
    end
  end

  def review_attempt_card attempt, show_player_name = true
    tag.div class: "attempt-card #{attempt.correct? ? 'correct-attempt' : 'incorrect-attempt'}" do
      tag.div(class: "attempt-team-part") do
        tag.div(class: "attempt-team-logo-container") do
          display_name_with_lazy_logo attempt.target_entity
        end +
        tag.p(attempt.target_entity.name, class: "attempt-team-name")
      end +
      
      (show_player_name ? tag.div(class: "attempt-player-part") do
        tag.div(class: "attempt-player-photo-container") do
          display_name_with_lazy_logo attempt.subject_entity
        end +
        tag.p(attempt.subject_entity.full_name, class: "attempt-player-name")
      end : "") +
      unless attempt.correct?
        tag.div "Your Guess: #{attempt.chosen_entity.name}", class: "chosen-team-indicator"
      end +
      tag.div(class: "attempt-timestamp") do
        time_ago_in_words(attempt.created_at) + " ago"
      end
    end
  end

  def game_attempts_panel game_attempts
    tag.div class: "game-attempts-panel" do
      tag.div class: "game-attempts-content" do
        if game_attempts.any?
          tag.div class: "attempts-grid" do
            safe_join game_attempts.map { |attempt| review_attempt_card(attempt) }
          end
        else
          tag.div class: "empty-attempts-message" do
            tag.p("You haven't made any game attempts yet.", class: "empty-attempts-text") +
            link_to("Start Playing", strength_team_match_path, class: "start-playing-button")
          end
        end
      end
    end
  end

  def player_guess_attempts_stats_panel player_stats, player
    tag.div class: "player-stats" do
      tag.div class: "stats-group" do
        tag.div(class: "stat-item") do
          tag.span("All-time", class: "stat-label") +
          tag.div(class: "stat-value") do
            tag.span("#{player_stats[player][:correct_attempts]}/#{player_stats[player][:total_attempts]}", class: "stat-fraction") +
            tag.span("(#{player_stats[player][:accuracy]}%)", class: "stat-percentage")
          end
        end +
        tag.div(class: "stat-item") do
          tag.span("Last Week", class: "stat-label") +
          tag.div(class: "stat-value") do
            tag.span("#{player_stats[player][:recent_correct]}/#{player_stats[player][:recent_total]}", class: "stat-fraction") +
            tag.span("(#{player_stats[player][:recent_accuracy]}%)", class: "stat-percentage")
          end
        end
      end
    end
  end

  def result_of_recent_game_attempts_for_player player, attempts_by_player, num_attempts = 5
    tag.div class: "player-attempts" do
      tag.h3("Recent Attempts", class: "attempts-heading") +
      tag.div(class: "attempts-list") do
        safe_join attempts_by_player[player].sort_by(&:created_at).reverse.take(num_attempts).map { |attempt| review_attempt_card(attempt, false) }
      end
    end
  end
end
