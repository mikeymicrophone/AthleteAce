class StadiumsController < ApplicationController
  include Filterable
  before_action :set_stadium, only: %i[ show ]

  def index
    @stadiums = apply_filter :stadiums
  end

  def show
  end

  private
    def set_stadium
      @stadium = Stadium.find(params.expect(:id))
    end
end
