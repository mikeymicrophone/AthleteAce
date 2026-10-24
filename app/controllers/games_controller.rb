class GamesController < ApplicationController
  def index
    @pagy, @contests = pagy(Game.order(begin_date: :desc, id: :desc), limit: 25)
    @catalog_title = "Games"
    render "contests/index"
  end

  def show
    @contest = Game.find(params[:id])
    render "contests/show"
  end
end
