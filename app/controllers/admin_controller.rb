class AdminController < ApplicationController
  before_action :authenticate_ace!
  before_action :require_admin!

  def index
    @ace_count = Ace.count
    @player_count = Player.count
    @team_count = Team.count
  end
end
