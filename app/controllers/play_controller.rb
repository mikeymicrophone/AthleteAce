class PlayController < ApplicationController
  before_action :authenticate_ace!, only: :drill

  def drill
    round = GameRoundSetup.new(include_inactive: true).start_misses! current_ace
    redirect_to game_round_path(round), status: :see_other
  rescue GameRound::InvalidAction => error
    redirect_to strength_path, alert: error.message, status: :see_other
  end

  def index
    scope = params.permit(:game_type, :length, :sport_id, :league_id, :season_id, :conference_id, :division_id,
      :team_id, :city_id, :state_id, :include_inactive, team_ids: [])
    return redirect_to new_game_round_path(scope) if scope.present?
    return unless current_ace

    @progress = PlayProgress.new ace: current_ace
    @misses = @progress.misses
    @players_today = @progress.players_today
    @history = GameHistory.new ace: current_ace
    @week = @history.current_week
    @unfinished_rounds = current_ace.game_rounds.unfinished.includes(:game_attempts).limit(3)
    @recent_rounds = current_ace.game_rounds.where.not(finished_at: nil).order(finished_at: :desc).limit(3)
    @active_goals = current_ace.goals.active.where(quest: Quest.approved).includes(quest: :highlights).order(updated_at: :desc).limit(3)
  end
end
