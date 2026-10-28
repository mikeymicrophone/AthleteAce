class Players::ShoutOutsController < ApplicationController
  def index
    @player = Player.find(params.expect(:player_id))
    seed = session[:shout_out_feed_seed] ||= SecureRandom.hex(16)
    posts = ShoutOutFeed.ranked(@player.shout_outs.live, seed: seed).includes(:created_by, :target)
    @pagy, @posts = pagy(posts, limit: 25)
    response.headers["Cache-Control"] = "private, no-store"
  end
end
