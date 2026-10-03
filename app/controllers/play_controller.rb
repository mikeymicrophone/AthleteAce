class PlayController < ApplicationController
  def index
    scope = params.permit(:game_type, :length, :sport_id, :league_id, :conference_id, :division_id,
      :team_id, :city_id, :state_id, :include_inactive, team_ids: [])
    return redirect_to new_game_round_path(scope) if scope.present?
    return unless current_ace

    @history = GameHistory.new ace: current_ace
    @week = @history.current_week
    @unfinished_rounds = current_ace.game_rounds.unfinished.includes(:game_attempts).limit(3)
    @recent_rounds = current_ace.game_rounds.where.not(finished_at: nil).order(finished_at: :desc).limit(3)
    @active_goals = current_ace.goals.active.includes(quest: :highlights).order(updated_at: :desc).limit(3)
  end
end
