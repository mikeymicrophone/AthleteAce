class TeamsController < ApplicationController
  before_action :set_team, only: %i[ show edit update destroy ]

  # GET /teams or /teams.json
  def index
    if params[:sport_id]
      @teams = Sport.find(params[:sport_id]).teams
    elsif params[:league_id]
      @teams = League.find(params[:league_id]).teams
    elsif params[:state_id]
      @teams = State.find(params[:state_id]).teams
    elsif params[:city_id]
      @teams = City.find(params[:city_id]).teams
    elsif params[:stadium_id]
      @teams = Stadium.find(params[:stadium_id]).teams
    else
      @teams = Team.all
    end

    # Apply sorting if requested
    case params[:sort]
    when 'mascot'
      @teams = @teams.order(:mascot)
    when 'territory'
      @teams = @teams.order(:territory)
    when 'sport'
      @teams = @teams.includes(league: :sport).order('sports.name')
    when 'city'
      @teams = @teams.includes(:stadium).order('stadiums.city_id')
    end
  end

  # GET /teams/1 or /teams/1.json
  def show
  end

  # GET /teams/new
  def new
    @team = Team.new
  end

  # GET /teams/1/edit
  def edit
  end

  # POST /teams or /teams.json
  def create
    @team = Team.new(team_params)

    respond_to do |format|
      if @team.save
        format.html { redirect_to @team, notice: "Team was successfully created." }
        format.json { render :show, status: :created, location: @team }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @team.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /teams/1 or /teams/1.json
  def update
    respond_to do |format|
      if @team.update(team_params)
        format.html { redirect_to @team, notice: "Team was successfully updated." }
        format.json { render :show, status: :ok, location: @team }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @team.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /teams/1 or /teams/1.json
  def destroy
    @team.destroy!

    respond_to do |format|
      format.html { redirect_to teams_path, status: :see_other, notice: "Team was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_team
      @team = Team.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def team_params
      params.expect(team: [ :mascot, :territory, :league_id, :stadium_id, :founded_year, :abbreviation, :url, :logo_url, :primary_color, :secondary_color ])
    end
end
