class PlayerGroupsController < ApplicationController
  before_action :authenticate_ace!, except: [ :index, :show ]
  before_action :require_admin!, except: [ :index, :show ]
  before_action :set_group, only: [ :show, :edit, :update, :destroy ]

  def index
    @pagy, @player_groups = pagy(PlayerGroup.order(:name))
  end

  def show
    @progress = PlayProgress.new(ace: current_ace, players: @player_group.players) if current_ace
    @pagy, @players = pagy(@player_group.players.order(:last_name, :first_name))
  end

  def new
    @player_group = PlayerGroup.new
  end

  def edit
  end

  def create
    @player_group = PlayerGroup.new(group_params)
    if @player_group.save
      redirect_to @player_group, notice: "Player group created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @player_group.update(group_params)
      redirect_to @player_group, notice: "Player group updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @player_group.destroy!
    redirect_to player_groups_path, status: :see_other, notice: "Player group deleted."
  end

  private

  def set_group
    @player_group = PlayerGroup.find(params[:id])
  end

  def group_params
    params.require(:player_group).permit(:name, :description, player_ids: [])
  end
end
