class TeamsController < ApplicationController
  include Filterable
  include FilterLoader
  before_action :set_team, only: %i[ show edit update destroy ]
  # We no longer need to specify filterable_by here since it's in the config file

  # GET /teams or /teams.json
  def index
    # Apply filters based on params
    @teams = apply_filters Team.all
    
    # Load current filters and options for the UI
    load_current_filters
    load_filter_options
    
    # Include common associations and paginate
    @teams = @teams.includes(:league, :stadium, :country, :state).order(:name)

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

    # Paginate the teams collection
    @pagy, @teams = pagy @teams, items: params[:per_page] || Pagy::DEFAULT[:items]

    @spectrums = Spectrum.all
    
    # Set current spectrum ID if provided in params
    set_current_spectrum_id(params[:spectrum_id]) if params[:spectrum_id].present?
  end

  # GET /teams/1 or /teams/1.json
  def show
    # Load any filters that were applied when navigating to this show page
    load_current_filters
    
    # Load related ratings
    @team_ratings = @team.ratings.includes(:ace).order(created_at: :desc).limit(10)
    
    # Set up filter options for navigation to related resources
    load_filter_options
    
    # Create a filtered breadcrumb for this team
    @filtered_breadcrumb = build_filtered_breadcrumb @team, @current_filters
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
