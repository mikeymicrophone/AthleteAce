class LeaguesController < ApplicationController
  include Filterable
  include FilterLoader
  before_action :set_league, only: %i[ show ]

  def index
    @current_filters = load_current_filters
    
    base_query = apply_filter :leagues
    
    @sort_service = HierarchicalSortService.from_params(params)
    
    # Add joins based on what sorting requires
    required_joins = @sort_service.required_joins
    if required_joins.any?
      base_query = base_query.joins(required_joins)
    end
    
    # Always include for display purposes
    base_query = base_query.includes(:sport, :country)
    
    sql_order = @sort_service.to_sql_order
    
    if sql_order
      @leagues = base_query.order(Arel.sql(sql_order))
    else
      @leagues = base_query.order(:name)
    end
    
    load_filter_options
  end

  def show
    load_current_filters
    @teams = @league.teams.includes(:stadium).order(:name)
    load_filter_options
    @filtered_breadcrumb = build_filtered_breadcrumb @league, @current_filters
  end

  private
    def set_league
      @league = League.find(params.expect(:id))
    end
end
