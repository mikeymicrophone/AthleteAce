class MembershipsController < ApplicationController
  before_action :set_membership, only: %i[ show edit update destroy ]

  # GET /memberships or /memberships.json
  def index
    @memberships = Membership.all
  end

  # GET /memberships/1 or /memberships/1.json
  def show
  end

  # GET /memberships/new
  def new
    @membership = Membership.new
    @teams = Team.all
    @divisions = Division.all
  end

  # GET /memberships/1/edit
  def edit
    @teams = Team.all
    @divisions = Division.all
  end

  # POST /memberships or /memberships.json
  def create
    @membership = Membership.new(membership_params)

    # If this is a new active membership, deactivate any existing active memberships for this team
    if @membership.active?
      Membership.where(team_id: @membership.team_id, active: true).update_all(active: false)
    end

    respond_to do |format|
      if @membership.save
        format.html { redirect_to membership_url(@membership), notice: "Membership was successfully created." }
        format.json { render :show, status: :created, location: @membership }
      else
        @teams = Team.all
        @divisions = Division.all
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @membership.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /memberships/1 or /memberships/1.json
  def update
    # If this membership is being activated, deactivate any existing active memberships for this team
    if membership_params[:active] == "true" && !@membership.active?
      Membership.where(team_id: @membership.team_id, active: true).where.not(id: @membership.id).update_all(active: false)
    end

    respond_to do |format|
      if @membership.update(membership_params)
        format.html { redirect_to membership_url(@membership), notice: "Membership was successfully updated." }
        format.json { render :show, status: :ok, location: @membership }
      else
        @teams = Team.all
        @divisions = Division.all
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @membership.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /memberships/1 or /memberships/1.json
  def destroy
    @membership.destroy

    respond_to do |format|
      format.html { redirect_to memberships_url, notice: "Membership was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_membership
      @membership = Membership.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def membership_params
      params.require(:membership).permit(:team_id, :division_id, :start_date, :end_date, :active)
    end
end
