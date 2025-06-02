class LeaguesController < ApplicationController
  include Filterable
  include FilterLoader
  before_action :set_league, only: %i[ show edit update destroy ]
  # We no longer need filterable_by as it's defined in the config file

  # GET /leagues or /leagues.json
  def index
    # Apply filters based on params
    @leagues = apply_filters League.all
    
    # Load current filters and options for the UI
    load_current_filters
    load_filter_options
    
    # Include common associations and paginate
    @leagues = @leagues.includes(:sport, :country).order(:name)
  end

  # GET /leagues/1 or /leagues/1.json
  def show
    # Load any filters that were applied when navigating to this show page
    load_current_filters
    
    # Load teams for this league
    @teams = @league.teams.includes(:stadium).order(:name)
    
    # Set up filter options for navigation to related resources
    load_filter_options
    
    # Create a filtered breadcrumb for this league
    @filtered_breadcrumb = build_filtered_breadcrumb @league, @current_filters
  end

  # GET /leagues/new
  def new
    @league = League.new
  end

  # GET /leagues/1/edit
  def edit
  end

  # POST /leagues or /leagues.json
  def create
    @league = League.new(league_params)

    respond_to do |format|
      if @league.save
        format.html { redirect_to @league, notice: "League was successfully created." }
        format.json { render :show, status: :created, location: @league }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @league.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /leagues/1 or /leagues/1.json
  def update
    respond_to do |format|
      if @league.update(league_params)
        format.html { redirect_to @league, notice: "League was successfully updated." }
        format.json { render :show, status: :ok, location: @league }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @league.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /leagues/1 or /leagues/1.json
  def destroy
    @league.destroy!

    respond_to do |format|
      format.html { redirect_to leagues_path, status: :see_other, notice: "League was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_league
      @league = League.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def league_params
      params.expect(league: [ :name, :url, :ios_app_url, :year_of_origin, :official_rules_url, :sport_id ])
    end
end
