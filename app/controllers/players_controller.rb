class PlayersController < ApplicationController
  include Filterable
  include FilterLoader
  before_action :set_player, only: %i[ show edit update destroy ]
  
  def index
    load_current_filters
    
    base_query = apply_filter :players
    
    @sort_service = HierarchicalSortService.from_params(params)
    
    required_joins = @sort_service.required_joins(:players)
    if required_joins.any?
      base_query = base_query.joins(required_joins)
    end
    
    base_query = base_query.includes(:positions, team: {league: :sport})
    
    sql_order = @sort_service.to_sql_order
    
    if sql_order
      @players = base_query.order(Arel.sql(sql_order))
    else
      @players = base_query.order(:first_name)
    end
    
    @spectrums = Spectrum.all
    
    set_current_spectrum_id params[:spectrum_id] if params[:spectrum_id].present?
    
    load_filter_options
    
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
