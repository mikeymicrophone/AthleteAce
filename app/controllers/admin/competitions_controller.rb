class Admin::CompetitionsController < ApplicationController
  before_action :authenticate_ace!
  before_action :require_admin!
  before_action { response.headers["Cache-Control"] = "private, no-store" }

  def index
    @directory = Admin::CompetitionDirectory.new(params)
    @pagy, @competitions = pagy(@directory.records, limit: 25)
    ids = @competitions.map(&:id)
    @entrant_counts = Contestant.where(contest_id: ids).group(:contest_id).count
    @game_counts = ContestGame.where(contest_id: ids).group(:contest_id).count
    @title_counts = TitleAward.where(contest_id: ids).group(:contest_id).count
    @kinds = Contest.competitions.where.not(kind: [ nil, "" ]).distinct.order(:kind).pluck(:kind)
    @seasons = Season.includes(:year, :league).recent
    @teams = Team.order(:territory, :mascot, :id)
  rescue ArgumentError => error
    render plain: error.message, content_type: "text/plain", status: :bad_request
  end

  def show
    @competition = Contest.competitions.includes(:context, season: [ :year, :league ]).find(params[:id])
    @tab = params[:tab].presence || "entrants"
    return render plain: "Choose entrants or titles.", status: :bad_request unless %w[entrants titles].include?(@tab)

    @entrant_count = @competition.contestants.count
    @game_count = @competition.contest_games.count
    @title_count = @competition.title_awards.count
    records = if @tab == "titles"
      @competition.title_awards.includes(winner: { campaign: [ :team, { season: [ :year, :league ] } ] }).order(:key, :id)
    else
      @competition.contestants.includes(campaign: [ :team, { season: [ :year, :league ] } ]).order(:id)
    end
    @pagy, @records = pagy(records, limit: 25)
  end
end
