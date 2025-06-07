class DivisionsController < ApplicationController
  include Filterable
  before_action :set_division, only: %i[ show ]

  def index
    @divisions = apply_filter :divisions
    
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
