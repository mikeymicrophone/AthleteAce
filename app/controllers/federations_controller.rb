class FederationsController < ApplicationController
  before_action :set_federation, only: %i[ show ]

  # GET /federations or /federations.json
  def index
    @federations = Federation.all
  end

  # GET /federations/1 or /federations/1.json
  def show
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_federation
      @federation = Federation.find(params.expect(:id))
    end
end
