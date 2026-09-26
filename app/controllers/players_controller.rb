class PlayersController < ApplicationController
  include Filterable
  include FilterLoader
  before_action :set_player, only: %i[ show ]
  
  def index
    load_current_filters
    
    base_query = apply_filter :players
    
    @sort_service = HierarchicalSortService.from_params(params)
    
    required_joins = @sort_service.required_joins(:players)
    if required_joins.any?
      base_query = base_query.joins(required_joins)
    end
    
    base_query = base_query.includes(
      :positions,
      team: [
        { league: :sport },
        { current_organization_affiliation: :organization }
      ]
    )
    
    sql_order = @sort_service.to_sql_order(:players)
    
    if sql_order
      @players = base_query.order(Arel.sql(sql_order))
    else
      @players = base_query.order(:first_name)
    end
    
    @spectrums = Spectrum.all
    
    set_current_spectrum_id params[:spectrum_id] if params[:spectrum_id].present?
    
    load_filter_options
    
    @pagy, @players = pagy(@players, limit: per_page(20))
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_player
      @player = Player.find(params.expect(:id))
    end
end
