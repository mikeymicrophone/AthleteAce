class CampaignsController < ApplicationController
  include Filterable
  before_action :set_campaign, only: %i[ show ]

  def index
    @campaigns = apply_filter :campaigns
  end

  def show
  end

  private
    def set_campaign
      @campaign = Campaign.find(params[:id])
    end
end