class SportsController < ApplicationController
  include Filterable
  before_action :set_sport, only: %i[ show ]

  def index 
    @sports = apply_filter :sports
  end

  def show
  end

  private
    def set_sport
      @sport = Sport.find(params.expect(:id))
    end
end
