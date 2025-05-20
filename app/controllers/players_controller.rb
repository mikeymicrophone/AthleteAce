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
    else
      Player.all
    end
    
    # Parse sort parameters - can be a single string or an array of sort fields
    sort_params = if params[:sort].present?
      params[:sort].is_a?(Array) ? params[:sort] : [params[:sort]]
    else
      ["first_name"] # Default sort
    end
    
    # Start with the base query
    query = base_query
    
    # Track if we need to add specific joins
    needs_league_join = false
    needs_sport_join = false
    needs_team_join = false
    needs_position_join = false
    
    # Determine required joins based on all sort fields
    sort_params.each do |sort_field|
      case sort_field
      when "league_id", "league.name"
        needs_league_join = true
        needs_team_join = true
      when "sport_id", "sport.name"
        needs_sport_join = true
        needs_league_join = true
        needs_team_join = true
      when "team_id", "team.name", "teams.mascot", "teams.territory"
        needs_team_join = true
      when "position_id", "position.name", "positions.name"
        needs_position_join = true
      end
    end
    
    # Apply necessary joins
    query = query.joins(:team) if needs_team_join
    query = query.joins(:team => :league) if needs_league_join
    query = query.joins(:team => {:league => :sport}) if needs_sport_join
    query = query.joins(:primary_position) if needs_position_join
    
    # Handle special case for random sorting
    if sort_params.include?("random")
      @players = query.order(Arel.sql("RANDOM()"))
    else
      # Build the order clause for multiple fields
      order_clauses = sort_params.map do |sort_field|
        case sort_field
        when "league_id", "league.name"
          "leagues.name"
        when "sport_id", "sport.name"
          "sports.name"
        when "team_id", "team.name"
          "teams.mascot"
        when "position_id", "position.name", "positions.name"
          "positions.name"
        else
          sort_field
        end
      end
      
      @players = query.order(order_clauses.join(", "))
    end
    
    # Load available spectrums for the rating selector
    @spectrums = Spectrum.all
    
    # Set current spectrum ID if provided in params
    set_current_spectrum_id(params[:spectrum_id]) if params[:spectrum_id].present?
    
    @pagy, @players = pagy(@players)
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
