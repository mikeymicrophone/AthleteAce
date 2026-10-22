class FeedPostsController < ApplicationController
  def show
    @post = ShoutOut.live.includes(:created_by, :target).find(params[:id])
    response.headers["Cache-Control"] = "private, no-store"
  end
end
