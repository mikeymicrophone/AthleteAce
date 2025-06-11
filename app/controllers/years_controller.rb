class YearsController < ApplicationController
  before_action :set_year, only: [:show]
  
  def index
    @pagy, @years = pagy Year.recent, limit: 25
  end

  def show
  end

  private

  def set_year
    @year = Year.find params[:id]
  end
end
