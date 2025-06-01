module ReviewHelper
  def team_attempts_filter_button(team)
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

  def sport_group_team_buttons(sport)
    tag.div class: "sport-section" do
      tag.h3(sport.name, class: "sport-title") +
      tag.div(class: "teams-buttons") do
        safe_join @teams_by_sport[sport].map { |team| team_attempts_filter_button(team) }
      end
    end
  end
end
