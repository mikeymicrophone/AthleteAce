class LeaguesController < ApplicationController
  include Filterable
  include FilterLoader
  before_action :set_league, only: %i[ show ]

  def index
    @leagues = apply_filter :leagues
    load_current_filters
    load_filter_options
    @leagues = @leagues.includes(:sport, :country).order(:name)
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
