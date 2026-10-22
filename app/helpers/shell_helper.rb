module ShellHelper
  def shell_sides
    [ [ "play", "Play", "player-play", strength_path ], [ "feed", "Feed", "star", feed_path ],
      [ "mod", "Moderate", "shield-check", moderation_path ], [ "admin", "Admin", "layout-grid", admin_path ] ]
      .select { |side, _label, _glyph, _path| available_sides.include?(side) }
  end

  def shell_tabs
    case current_side
    when "play"
      [ [ "Home", "home", strength_path ], [ "Games", "player-play", new_game_round_path ],
        [ "Quests", "script", quests_path(side: "play") ], [ "History", "history", strength_game_attempts_path ],
        [ "Browse", "layout-grid", browse_path(side: "play") ] ]
    when "feed"
      [ [ "Latest", "star", feed_path ], [ "Leaders", "tournament", shout_out_leaderboard_path ], [ "Players", "shirt-sport", players_path(side: "feed") ],
        [ "Teams", "shield", teams_path(side: "feed") ] ]
    when "mod"
      [ [ "Queue", "shield-check", moderation_path ], [ "Reports", "flag", reports_path ], [ "Decision log", "history", moderation_log_path ] ]
    when "admin"
      [ [ "Overview", "home", admin_path ], [ "Revenue", "list-numbers", shout_out_revenue_path ], [ "Sports data", "layout-grid", browse_path(section: "sports", side: "admin") ],
        [ "Content catalog", "script", browse_path(section: "content", side: "admin") ] ]
    end
  end

  def active_shell_tab
    case current_side
    when "mod" then controller_name == "reports" ? "Reports" : (action_name == "log" ? "Decision log" : "Queue")
    when "admin"
      return "Revenue" if controller_name == "shout_out_revenues"
      controller_name == "admin" ? "Overview" : (params[:section] == "content" ? "Content catalog" : "Sports data")
    when "feed"
      return "Leaders" if controller_name == "shout_out_leaderboards"
      { "players" => "Players", "teams" => "Teams" }.fetch(controller_name, "Latest")
    else
      return "History" if controller_name == "game_attempts" || (controller_name == "strength" && action_name.include?("game_attempts"))
      return "Games" if %w[game_rounds strength division_guessing_games play_previews].include?(controller_name)
      return "Quests" if %w[quests goals achievements highlights].include?(controller_name)
      controller_name == "play" ? "Home" : "Browse"
    end
  end

  def shell_pending_count
    @shell_pending_count ||= Moderation::Queue.new(reviewer: current_ace).total
  end

  def shell_streak
    (@progress || PlayProgress.new(ace: current_ace)).streaks.fetch(:current)
  end
end
