require "rails_helper"

RSpec.describe "Organization contracts", type: :request do
  let(:organization) { create :organization, name: "Club organization" }
  let(:player) { create :player, team: nil, sport: create(:hockey) }
  let!(:contract) { Contract.create! organization: organization, player: player, total_dollar_value: 16000000 }

  it "renders organization-only contracts on the index and show pages" do
    get contracts_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(organization.name, player.name, "Duration unknown")
    get contract_path(contract)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Organization:", organization.name, "$16,000,000", "Not specified")
    expect(response.body).to include(organization_path(organization))
  end

  it "filters contracts by their contracting organization" do
    another = Contract.create! player: player, organization: create(:organization, name: "Another club")
    get organization_contracts_path(organization)
    expect(response).to have_http_status(:ok)
    rows = Nokogiri::HTML(response.body).css(".contract-record").map { |node| node["id"] }
    expect(rows).to eq([ "contract_#{contract.id}" ])
    expect(rows).not_to include("contract_#{another.id}")
  end
end
