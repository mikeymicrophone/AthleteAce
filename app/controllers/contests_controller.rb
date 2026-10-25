class ContestsController < ApplicationController
  include Filterable
  before_action :set_contest, only: [:show]
  
  def index
    @pagy, @contests = pagy apply_filter(:contests).competitions.order(begin_date: :desc, id: :desc), limit: 25
  end

  def show
  end

  private

  def set_contest
    @contest = Contest.find params[:id]
  end
end
