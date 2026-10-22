class TeamsController < ApplicationController
  include Filterable
  include FilterLoader
  before_action :set_team, only: %i[ show ]

  def index
    @current_filters = load_current_filters
    load_filter_options
    
    # Build the base query using the filters
    base_query = apply_filter :teams

    # Build the query with proper joins for sorting and searching
    base_query = base_query.includes(:league, :division, :conference)
                       .joins(:league => :sport)
                       .includes(:stadium => :city)
                       .select("teams.*, leagues.name as league_name, sports.name as sport_name")
    
    # Initialize Ransack search object
    @q = base_query.ransack(params[:q])
    
    # Set default sort if none specified
    @q.sorts = 'teams.territory asc' if @q.sorts.empty?
    
    # Get the teams from search or filtering
    if params[:q].present?
      @teams = @q.result.distinct
    else
      @teams = base_query
      
      # Apply sorting if requested
      case params[:sort]
      when 'mascot'
        @teams = @teams.order('teams.mascot')
      when 'territory'
        @teams = @teams.order('teams.territory')
      when 'sport'
        @teams = @teams.order('sports.name')
      when 'city'
        @teams = @teams.joins(stadium: :city).order('cities.name')
      else
        @teams = @teams.order('teams.territory')
      end
    end

    # Paginate the teams collection
    @pagy, @teams = pagy @teams, limit: per_page

    @spectrums = Spectrum.visible_to(current_ace)
    
    # Set current spectrum ID if provided in params
    set_current_spectrum_id(params[:spectrum_id]) if params[:spectrum_id].present?
  end

  # GET /teams/1 or /teams/1.json
  def show
    @tab = params[:tab].presence || "wall"
    @wall_filter = params[:wall_filter].presence || "all"
    raise ActionController::BadRequest unless %w[wall roster ratings].include?(@tab) && %w[all team players].include?(@wall_filter)
    # Load any filters that were applied when navigating to this show page
    load_current_filters
    
    # Load related ratings
    @team_ratings = @team.ratings.includes(:ace).order(created_at: :desc).limit(10)
    
    # Set up filter options for navigation to related resources
    load_filter_options
    
    # Create a filtered breadcrumb for this team
    @filtered_breadcrumb = build_filtered_breadcrumb @team, @current_filters
    if @tab == "wall"
      posts = ShoutOut.approved.where(funding_status: "spent", team_id: @team.id)
      weekly = posts.where(id: ModerationDecision.where(subject_type: "ShoutOut", action: "approved", created_at: Time.current.beginning_of_week..).select(:subject_id))
      @weekly_count = weekly.count
      @most_shouted = weekly.where(target_type: "Player").group(:target_id, :target_name)
        .order(Arel.sql("COUNT(*) DESC"), :target_name, :target_id).limit(5).pluck(:target_name, Arel.sql("COUNT(*)"))
      posts = posts.where(target_type: @wall_filter == "team" ? "Team" : "Player") unless @wall_filter == "all"
      seed = session[:shout_out_feed_seed] ||= SecureRandom.hex(16)
      @pagy, @posts = pagy(ShoutOutFeed.ranked(posts.includes(:created_by, :target), seed: seed), limit: 25)
    elsif @tab == "roster"
      @pagy, @players = pagy(@team.players.order(:last_name, :first_name, :id), limit: 25)
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_team
      @team = Team.find(params.expect(:id))
    end
end
