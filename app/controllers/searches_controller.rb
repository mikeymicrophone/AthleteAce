class SearchesController < ApplicationController
  def index
    @search = ShellSearch.new(query: params[:q], side: current_side, ace: current_ace)
    @groups = @search.groups
    response.headers["Cache-Control"] = "no-store"
    render partial: "results" if request.xhr?
  end
end
