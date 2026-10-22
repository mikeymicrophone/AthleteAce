class FeedController < ApplicationController
  def index
    @view = params[:view].presence || "all"
    raise ActionController::BadRequest unless %w[all my_teams].include?(@view)
    return unless @view == "my_teams" && current_ace

    @league = League.find(params[:league_id]) if params[:league_id].present?
    @leagues = League.order(:name)
    followed = current_ace.follows.where(followable_type: "Team")
    affinity = current_ace.ratings.active.where(target_type: "Team", spectrum: Spectrum.approved.where(name: "Affinity"))
      .where("value >= 5000")
    teams = Team.where(id: followed.select(:followable_id)).or(Team.where(id: affinity.select(:target_id)))
    teams = teams.where(league: @league) if @league
    @pagy, @teams = pagy(teams.includes(:league).order(:territory, :mascot, :id))
    ids = @teams.map(&:id)
    @followed_ids = followed.where(followable_id: ids).pluck(:followable_id)
    @affinity_ids = affinity.where(target_id: ids).pluck(:target_id)
  end
end
