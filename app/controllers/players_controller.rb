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
    
    @spectrums = Spectrum.visible_to(current_ace)
    
    set_current_spectrum_id params[:spectrum_id] if params[:spectrum_id].present?
    
    load_filter_options
    
    @pagy, @players = pagy(@players, limit: per_page(20))
  end

  # GET /players/1 or /players/1.json
  def show
    load_current_filters
    @filtered_breadcrumb = build_filtered_breadcrumb @player, @current_filters
    @spectrums = Spectrum.visible_to(current_ace).order :name
    @seasons = Season.where(id: @player.campaigns.select(:season_id)).includes(:year, :league).recent

    if ace_signed_in?
      attempts = current_ace.game_attempts.where subject_entity: @player
      seen = attempts.count
      right = attempts.where(is_correct: true).count
      last_miss = attempts.where(is_correct: false).maximum :created_at
      @memory_stats = {
        seen: seen,
        accuracy: seen.positive? ? "#{(right.fdiv(seen) * 100).round}%" : "—",
        quests: current_ace.goals.where(quest: Quest.approved).joins(:goal_achievements).where("goal_achievements.required_player_ids @> ?::jsonb", [ @player.id ].to_json).distinct.count,
        last_miss: last_miss ? last_miss.in_time_zone(current_ace.play_time_zone).to_date.strftime("%b %-d, %Y") : "—"
      }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_player
      @player = Player.find(params.expect(:id))
    end
end
