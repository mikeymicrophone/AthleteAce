class OrganizationAffiliationsController < ApplicationController
  def index
    @organization_affiliations = OrganizationAffiliation.includes(:organization, team: :league).chronological
  end

  def show
    @organization_affiliation = OrganizationAffiliation.includes(:organization, team: :league).find(params.expect(:id))
  end
end
