class SeasonsController < ApplicationController
  before_action :set_season, only: [:show]
  
  def index
    @pagy, @seasons = pagy Season.recent.includes(:year, :league), limit: 25
  end

  def show
  end

  private

  def set_season
    @season = Season.includes(:year, league: :sport, campaigns: :team).find params[:id]
  end
end
