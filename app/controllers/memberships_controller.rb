class MembershipsController < ApplicationController
  include Filterable
  before_action :set_membership, only: %i[ show ]

  def index
    @memberships = apply_filter :memberships
  end

  def show
  end

  private
    def set_membership
      @membership = Membership.find(params[:id])
    end
end
