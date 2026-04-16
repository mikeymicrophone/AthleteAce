class OrganizationsController < ApplicationController
  def index
    @organizations = Organization.includes(current_organization_affiliations: :team).order(:name)
  end

  def show
    @organization = Organization.includes(organization_affiliations: { team: :league }).find(params.expect(:id))
  end
end
