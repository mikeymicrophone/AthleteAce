class ShoutOutLeaderboardsController < ApplicationController
  def index
    @sport = Sport.find(params.expect(:sport_id)) if params[:sport_id].present?
    @league = League.find(params.expect(:league_id)) if params[:league_id].present?
    @leaderboard = ShoutOutLeaderboard.new(week: params[:week], kind: params[:kind] || "players", sport_id: @sport&.id, league_id: @league&.id)
    @pagy, @rows = pagy(@leaderboard.rows, limit: 25)
    @targets = @leaderboard.model.where(id: @rows.pluck(:id)).index_by(&:id)
    @sports = Sport.order(:name)
    @leagues = League.order(:name)
    if @rows.first
      seed = session[:shout_out_feed_seed] ||= SecureRandom.hex(16)
      @top_post = ShoutOutFeed.ranked(@leaderboard.posts.where(target_id: @rows.first.fetch(:id)), seed: seed).includes(:created_by, :target).first
    end
    response.headers["Cache-Control"] = "private, no-store"
  rescue Date::Error, ArgumentError => error
    render plain: error.message, status: :bad_request
  end
end
