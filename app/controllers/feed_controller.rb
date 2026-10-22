class FeedController < ApplicationController
  def index
    @view = params[:view].presence || "all"
    raise ActionController::BadRequest unless %w[all my_teams].include?(@view)
    load_posts unless @view == "my_teams" && !current_ace
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

  private

  def load_posts
    posts = ShoutOut.approved.where(funding_status: "spent")
    if current_ace
      posts = posts.or(ShoutOut.where(created_by: current_ace, moderation_status: "pending", funding_status: "reserved"))
    end
    if @view == "my_teams"
      followed = current_ace.follows.where(followable_type: "Team").select(:followable_id)
      affinity = current_ace.ratings.active.where(target_type: "Team", spectrum: Spectrum.approved.where(name: "Affinity"))
        .where("value >= 5000").select(:target_id)
      posts = posts.where(team_id: followed).or(posts.where(team_id: affinity))
      posts = posts.where(league_id: params[:league_id]) if params[:league_id].present?
    end
    seed = session[:shout_out_feed_seed] ||= SecureRandom.hex(16)
    @posts_pagy, @posts = pagy(ShoutOutFeed.ranked(posts.includes(:created_by, :target), seed: seed), page_key: "posts_page")
  end
end
