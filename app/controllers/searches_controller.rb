class SearchesController < ApplicationController
  def index
    seed = session[:shout_out_feed_seed] ||= SecureRandom.hex(16)
    @search = ShellSearch.new(query: params[:q], side: current_side, ace: current_ace, seed: seed)
    @groups = @search.groups
    response.headers["Cache-Control"] = "no-store"
    render partial: "results" if request.xhr?
  end
end
