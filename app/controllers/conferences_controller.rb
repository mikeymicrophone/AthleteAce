class ConferencesController < ApplicationController
  include Filterable
  before_action :set_conference, only: %i[ show ]

  def index
    @conferences = apply_filter :conferences
  end

  def show
    @divisions = @conference.divisions
    @teams = @conference.teams
  end

  private
    def set_conference
      @conference = Conference.find(params[:id])
    end
end
