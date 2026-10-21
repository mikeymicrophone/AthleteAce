require "rails_helper"

RSpec.describe "Seasonal player browsing", type: :request do
  let(:league) { create :nba }
  let(:team) { create :team, league: league }
  let(:season) { create :season, league: league, label: "2025_2026" }
  let(:campaign) { Campaign.create! team: team, season: season }
  let(:player) { create :player, team: nil, sport: league.sport }
  let!(:activation) { Activation.create! player: player, campaign: campaign }

  it "shows campaign players and the full season label without requiring contracts" do
    get campaign_activations_path(campaign)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(player.name, team.name, "2025_2026", "1 known seasonal player")
    expect(Nokogiri::HTML(response.body).css(".activation-contract-tag")).to be_empty
  end

  it "shows membership details with unknown dates and no contract" do
    get activation_path(activation)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(player.name, team.name, "Not specified")
    expect(response.body).not_to include("Contract #")
  end

  it "retains contract links and values when a verified organization contract is supplied" do
    contract = Contract.create! player: player, organization: create(:organization), total_dollar_value: 16000000
    activation.update! contract: contract
    get campaign_activations_path(campaign)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(contract_path(contract), "$16,000,000")
    get activation_path(activation)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(contract_path(contract), "$16,000,000")
  end
end
