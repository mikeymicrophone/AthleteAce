class Admin::PlayerHistoriesController < ApplicationController
  before_action :authenticate_ace!
  before_action :require_admin!
  before_action { response.headers["Cache-Control"] = "private, no-store" }

  def show
    @player = Player.includes(:team).find(params[:id])
    @tab = params[:tab].presence || "stints"
    return render plain: "Choose a player history tab.", status: :bad_request unless %w[stints contracts transactions rosters appearances].include?(@tab)

    @counts = { stints: @player.stints.count, contracts: @player.contracts.count, transactions: @player.transaction_players.count,
      rosters: @player.roster_entries.count, appearances: @player.appearances.count }
    records = case @tab
    when "stints"
      @player.stints.includes(:team, :start_transaction, :end_transaction, contract: :organization)
        .order(Arel.sql("stints.start_date DESC NULLS LAST, stints.id DESC"))
    when "contracts"
      @player.contracts.includes(:organization, :team).order(Arel.sql("contracts.start_date DESC NULLS LAST, contracts.id DESC"))
    when "transactions"
      @player.transaction_players.joins(:event).includes(:event, :from_team, :to_team, :from_organization, :to_organization)
        .order(Arel.sql("transactions.effective_on DESC NULLS LAST, transactions.id DESC, transaction_players.id DESC"))
    when "rosters"
      @player.roster_entries.joins(:roster).includes(roster: { campaign: [ :team, { season: [ :year, :league ] } ] })
        .order(Arel.sql("rosters.effective_on DESC NULLS LAST, rosters.id DESC, roster_entries.id DESC"))
    when "appearances"
      @player.appearances.joins(contestant: :contest).includes(contestant: [ :contest, { campaign: [ :team, { season: [ :year, :league ] } ] } ])
        .order(Arel.sql("contests.begin_date DESC NULLS LAST, contests.id DESC, appearances.id DESC"))
    end
    @pagy, @records = pagy(records, limit: 25)
  end
end
