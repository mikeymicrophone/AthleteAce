# frozen_string_literal: true

# PlayerSearch encapsulates complex filtering and sampling logic for players.
# Pass in a params-like hash (already permitted) and call `#call` to get
# an ActiveRecord::Relation or Array (depending on sample) of players.
class PlayerSearch
  DEFAULT_SAMPLE_SIZE = 50

  def initialize(params, scope: Player.all)
    @params = params.symbolize_keys
    @scope  = scope
  end

  # Returns a sampled set of players based on the filters.
  # Uses DB-level `ORDER BY RANDOM()` to avoid loading full sets into memory.
  def call
    query = @scope
    query = query.where(team_id: @params[:team_ids])     if @params[:team_ids].present? && @params[:team_id].blank?
    query = query.where(team_id: @params[:team_id])      if @params[:team_id].present?
    
    query = query.joins(:team).where(teams: { league_id: @params[:league_id] }) if @params[:league_id].present?
    query = query.joins(:team, :league).where(leagues: { sport_id:  @params[:sport_id]  }) if @params[:sport_id].present?
    # query = query.where(active: true) unless @params[:include_inactive] == 'true'

    query.sampled(DEFAULT_SAMPLE_SIZE)
  end
end
