class PlayController < ApplicationController
  before_action :authenticate_ace!, only: [ :drill, :quick ]

  def drill
    round = GameRoundSetup.new(include_inactive: true).start_misses! current_ace
    redirect_to game_round_path(round), status: :see_other
  rescue GameRound::InvalidAction => error
    redirect_to strength_path, alert: error.message, status: :see_other
  end

  def quick
    if ReviewQueue.new(ace: current_ace).entries.any?
      round = GameRoundSetup.new(game_type: "phased_repetition", include_inactive: true).start!(current_ace)
    elsif PlayProgress.new(ace: current_ace).misses.any?
      round = GameRoundSetup.new(include_inactive: true).start_misses!(current_ace, limit: 10)
    else
      affinity = current_ace.ratings.active.where(target_type: "Team", spectrum: Spectrum.approved.where(name: "Affinity")).where("value > 0").order(value: :desc).limit(30).pluck(:target_id)
      setup = GameRoundSetup.new(team_ids: affinity)
      setup = GameRoundSetup.new if setup.available_count.zero?
      setup = setup.season_suggestion if setup.available_count.zero? && setup.season_suggestion
      round = setup.start!(current_ace)
    end
    redirect_to game_round_path(round), status: :see_other
  rescue ActiveModel::ValidationError, GameRound::InvalidAction => error
    redirect_to new_game_round_path, alert: error.message, status: :see_other
  end

  def index
    scope = params.permit(:practice_filter, :goal_achievement_id, :player_group_id, :game_type, :length, :sport_id, :league_id, :season_id, :conference_id, :division_id,
      :team_id, :city_id, :state_id, :include_inactive, team_ids: [], player_ids: [])
    return redirect_to new_game_round_path(scope) if scope.present?
    return unless current_ace

    @progress = PlayProgress.new ace: current_ace
    @due_count = ReviewQueue.new(ace: current_ace).entries.size
    @misses = @progress.misses
    @players_today = @progress.players_today
    group_key = Arel.sql("(scope ->> 'player_group_id')::bigint")
    group_ids = current_ace.game_rounds.where(created_at: ..Time.current, updated_at: ..Time.current)
      .where("(scope ->> 'player_group_id')::bigint IN (?)", PlayerGroup.select(:id))
      .group(group_key).order(Arel.sql("MAX(updated_at) DESC"), group_key).limit(3).pluck(group_key)
    @group_overviews = GroupPracticeOverview.new(groups: PlayerGroup.in_order_of(:id, group_ids), progress: @progress).rows
    @history = GameHistory.new ace: current_ace
    @week = @history.current_week
    @unfinished_rounds = current_ace.game_rounds.unfinished.includes(:game_attempts).limit(3)
    @recent_rounds = current_ace.game_rounds.where.not(finished_at: nil).order(finished_at: :desc).limit(3)
    @active_goals = current_ace.goals.active.where(quest: Quest.approved).includes(quest: :highlights).order(updated_at: :desc).limit(3)
  end
end
