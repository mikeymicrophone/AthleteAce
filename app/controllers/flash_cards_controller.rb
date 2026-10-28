# Show each player's team without scoring answers or saving a round.
class FlashCardsController < ApplicationController
  def show
    @setup = GameRoundSetup.new setup_params.merge(game_type: "flash_cards", ace: current_ace)
    @cards = @setup.valid? ? @setup.flash_cards : []
    return if @cards.any?

    redirect_to new_game_round_path(@setup.scope_params), status: :see_other,
      alert: @setup.errors.full_messages.to_sentence.presence || "No players in this scope. Try another team or league."
  end

  private

  def setup_params
    params.permit(:practice_filter, :goal_achievement_id, :player_group_id, :length, :sport_id, :league_id, :season_id, :conference_id, :division_id, :team_id,
      :city_id, :state_id, :include_inactive, :player_id, :delay, team_ids: [], player_ids: [])
  end
end
