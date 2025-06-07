class CitiesController < ApplicationController
  include Filterable
  before_action :set_city, only: %i[ show ]

  def index
    @cities = apply_filter :cities
  end

  def show
  end

  private
    def set_city
      @city = City.find params.expect(:id)
    end
end
