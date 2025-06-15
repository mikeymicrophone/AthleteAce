class ActivationsController < ApplicationController
  include Filterable
  before_action :set_activation, only: %i[show]

  def index
    base_query = apply_filter :activations
    base_query = base_query.includes(:contract, :campaign, 
                                   contract: [:player, :team], 
                                   campaign: [:season, season: :league])
    @pagy, @activations = pagy(base_query.order(start_date: :desc, created_at: :desc), limit: 25)
  end

  def show
  end

  private

  def set_activation
    @activation = Activation.find(params[:id])
  end
end