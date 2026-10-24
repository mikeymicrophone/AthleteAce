class AdminController < ApplicationController
  before_action :authenticate_ace!
  before_action :require_admin!
  before_action { response.headers["Cache-Control"] = "private, no-store" }

  def index
    @ace_count = Ace.count
    @player_count = Player.count
    @team_count = Team.count
    @overview = Admin::Overview.new(admin: current_ace)
  end
end
