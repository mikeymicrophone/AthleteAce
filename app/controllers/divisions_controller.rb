class DivisionsController < ApplicationController
  include Filterable
  include FilterLoader
  before_action :set_division, only: %i[ show ]

  def index
    load_current_filters
    
    base_query = apply_filter :divisions
    
    @sort_service = HierarchicalSortService.from_params(params)
    
    required_joins = @sort_service.required_joins(:divisions)
    if required_joins.any?
      base_query = base_query.joins(required_joins)
    end
    
    base_query = base_query.includes(:conference, conference: {league: :sport})
    
    sql_order = @sort_service.to_sql_order
    
    if sql_order
      @divisions = base_query.order(Arel.sql(sql_order))
    else
      @divisions = base_query.order(:name)
    end
    
    @spectrums = Spectrum.all
    
    # Set current spectrum ID if provided in params
    set_current_spectrum_id params[:spectrum_id] if params[:spectrum_id].present?
  end

  def show
    @teams = @division.teams
  end

  private
    def set_division
      @division = Division.find(params[:id])
    end
end
