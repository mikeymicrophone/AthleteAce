class ContractsController < ApplicationController
  include Filterable
  before_action :set_contract, only: %i[show]

  def index
    base_query = apply_filter :contracts
    base_query = base_query.includes(:player, :team, player: :team, team: [:league, league: :sport])
    @pagy, @contracts = pagy(base_query.order(start_date: :desc, created_at: :desc), limit: 25)
  end

  def show
  end

  private

  def set_contract
    @contract = Contract.find(params[:id])
  end
end