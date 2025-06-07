class PlayersController < ApplicationController
  include Filterable
  include FilterLoader
  before_action :set_player, only: %i[ show edit update destroy ]
  
  def index
    # Load current filters and set related instance variables
    @current_filters = load_current_filters
    
    # Build the base query using the filters
    base_query = apply_filter :players
  
    # Build the query with proper joins for sorting and searching
    base_query = base_query.joins(:team, team: [:league, league: :sport])
                          .left_joins(:positions)
                          .select("players.*, teams.mascot as team_name, teams.territory as team_territory, " +
                                 "leagues.name as league_name, sports.name as sport_name, positions.name as position_name")
    
    # Initialize Ransack search object
    @q = base_query.ransack(params[:q])
    
    # Set default sort if none specified
    @q.sorts = 'first_name asc' if @q.sorts.empty?
    
    # Handle random sorting as a special case
    if params[:random].present? && params[:random] == 'true'
      @players = base_query.order(Arel.sql('RANDOM()'))
    else
      # Get the result with distinct to avoid duplicates from joins
      @players = @q.result(distinct: true)
    end
    
    # Load available spectrums for the rating selector
    @spectrums = Spectrum.all
    
    # Set current spectrum ID if provided in params
    set_current_spectrum_id params[:spectrum_id] if params[:spectrum_id].present?
    
    # Load filter options for selector UI
    @filter_options = load_filter_options
    
    # Paginate the results
    @pagy, @players = pagy(@players, items: params[:per_page] || 20)
  end

  # GET /players/1 or /players/1.json
  def show
    # Load any filters that were applied when navigating to this show page
    load_current_filters
    
    # Load related ratings
    @ratings = @player.ratings.includes(:ace)
    @player_ratings = @player.ratings.includes(:ace).order(created_at: :desc).limit(10)
    @team_ratings = @player.team.ratings.includes(:ace).order(created_at: :desc).limit(10) if @player.team
    
    # Set up filter options for navigation to related resources
    load_filter_options
    
    # Create a filtered breadcrumb for this player
    @filtered_breadcrumb = build_filtered_breadcrumb @player, @current_filters
  end

  # GET /players/new
  def new
    @player = Player.new
  end

  # GET /players/1/edit
  def edit
  end

  # POST /players or /players.json
  def create
    @player = Player.new(player_params)

    respond_to do |format|
      if @player.save
        format.html { redirect_to @player, notice: "Player was successfully created." }
        format.json { render :show, status: :created, location: @player }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @player.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /players/1 or /players/1.json
  def update
    respond_to do |format|
      if @player.update(player_params)
        format.html { redirect_to @player, notice: "Player was successfully updated." }
        format.json { render :show, status: :ok, location: @player }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @player.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /players/1 or /players/1.json
  def destroy
    @player.destroy!

    respond_to do |format|
      format.html { redirect_to players_path, status: :see_other, notice: "Player was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_player
      @player = Player.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def player_params
      params.expect(player: [ :first_name, :last_name, :nicknames, :birthdate, :birth_city_id, :birth_country_id, :current_position, :debut_year, :draft_year, :active, :bio, :photo_urls, :team_id ])
    end
end
