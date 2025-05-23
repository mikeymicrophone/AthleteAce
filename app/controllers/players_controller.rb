class PlayersController < ApplicationController
  before_action :set_player, only: %i[ show edit update destroy ]

  # GET /players or /players.json
  def index
    # Start building the base query
    base_query = if params[:sport_id]
      Sport.find(params[:sport_id]).players
    elsif params[:league_id]
      League.find(params[:league_id]).players
    elsif params[:stadium_id]
      Stadium.find(params[:stadium_id]).players
    elsif params[:team_id]
      @team = Team.find(params[:team_id])
      @team.players
    elsif params[:state_id]
      @state = State.find(params[:state_id])
      @state.players
    elsif params[:city_id]
      @city = City.find(params[:city_id])
      @city.players
    else
      Player.all
    end
    
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
    set_current_spectrum_id(params[:spectrum_id]) if params[:spectrum_id].present?
    
    # Paginate the results
    @pagy, @players = pagy(@players, items: params[:per_page] || 20)
  end

  # GET /players/1 or /players/1.json
  def show
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
