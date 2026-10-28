class Admin::GamesController < ApplicationController
  before_action :authenticate_ace!
  before_action :require_admin!
  before_action { response.headers["Cache-Control"] = "private, no-store" }

  def index
    @directory = Admin::GameDirectory.new(params)
    @pagy, @games = pagy(@directory.records, limit: 25)
    @competitions = Contest.competitions.order(:name, :id)
    @seasons = Season.includes(:year, :league).recent
    @teams = Team.order(:territory, :mascot, :id)
    @appearance_counts = Appearance.joins(:contestant).where(contestants: { contest_id: @games.map(&:id) }).group("contestants.contest_id").count
  rescue ArgumentError => error
    render plain: error.message, content_type: "text/plain", status: :bad_request
  end

  def show
    @game = Game.find(params[:id])
    @tab = params[:tab].presence || "appearances"
    return render plain: "Choose appearances or rosters.", status: :bad_request unless %w[appearances rosters].include?(@tab)

    @contestants = @game.contestants.includes(campaign: [ :team, { season: [ :year, :league ] } ]).order(:id)
    @memberships = @game.competition_memberships.includes(:contest).order(:id)
    @rosters = Roster.none
    if @game.entity_code.present?
      @rosters = Roster.where(campaign_id: @contestants.map(&:campaign_id)).where("details ->> 'game_code' = ?", @game.entity_code)
    end
    if @tab == "rosters"
      entries = RosterEntry.where(roster_id: @rosters.select(:id)).includes(:player, roster: { campaign: :team }).order(:roster_id, :id)
    else
      entries = @game.appearances.includes(:player, contestant: { campaign: :team }).order(:contestant_id, :id)
    end
    @pagy, @entries = pagy(entries, limit: 25)
  end
end
