class CountriesController < ApplicationController
  include Filterable
  before_action :set_country, only: %i[ show ]

  def index
    @countries = apply_filter :countries
  end

  def show
  end

  private
    def set_country
      @country = Country.find params.expect(:id)
    end
end
