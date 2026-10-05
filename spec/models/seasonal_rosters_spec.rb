require "rails_helper"

RSpec.describe "Seasonal rosters", type: :model do
  let(:league) { create :nba }
  let(:season) { create :season, league: league, year: create(:year, number: 2024), label: "2024-25" }
  let(:first_team) { create :team, league: league }
  let(:second_team) { create :team, league: league }
  let(:player) { create :player, team: first_team, sport: league.sport }
  let(:first_campaign) { Campaign.create! team: first_team, season: season }
  let(:second_campaign) { Campaign.create! team: second_team, season: season }

  it "keeps a traded player on both whole-season rosters without contracts or invented dates" do
    first_membership = Activation.create! player: player, campaign: first_campaign
    second_membership = Activation.create! player: player, campaign: second_campaign
    player.update! team: second_team

    expect(first_campaign.reload.activated_players).to match_array([player])
    expect(second_campaign.reload.activated_players).to match_array([player])
    expect(player.reload.campaigns).to match_array([first_campaign, second_campaign])
    expect(league.activations).to match_array([first_membership, second_membership])
    expect(league.sport.activations).to match_array([first_membership, second_membership])
    expect(first_team.activations).to match_array([first_membership])
    expect(second_team.activations).to match_array([second_membership])
    expect(Player.where(id: player.id).count).to eq(1)
    expect(Contract.count).to eq(0)
    expect([first_membership, second_membership].map { |membership| [membership.start_date, membership.end_date] }).to eq([[nil, nil], [nil, nil]])
  end

  it "rejects a second membership for the same player and team-season" do
    Activation.create! player: player, campaign: first_campaign
    duplicate = Activation.new player: player, campaign: first_campaign

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:player_id]).to include("has already been taken")
  end

  it "infers the player from a supplied contract for existing callers" do
    contract = Contract.create! player: player, team: first_team
    membership = Activation.create! contract: contract, campaign: first_campaign

    expect(membership.reload.player).to eq(player)
    expect(player.reload.activations).to include(membership)
  end

  it "rejects a contract belonging to another player" do
    contract = Contract.create! player: player, team: first_team
    other_player = create :player, team: first_team
    membership = Activation.new player: other_player, contract: contract, campaign: first_campaign

    expect(membership).not_to be_valid
    expect(membership.errors[:contract]).to include("must belong to the roster player")
    expect(membership.player).to eq(other_player)
  end

  it "uses the campaign team for a loan while retaining the parent club's contract" do
    contract = Contract.create! player: player, team: first_team
    membership = Activation.create! player: player, contract: contract, campaign: second_campaign

    expect(membership.reload.team).to eq(second_team)
    expect(membership.contract.team).to eq(first_team)
    expect(second_campaign.reload.activated_players).to match_array([player])
    expect(second_team.activations).to include(membership)
    expect(first_team.activations).not_to include(membership)
  end

  it "preserves roster membership when an optional contract is deleted" do
    contract = Contract.create! player: player, team: first_team
    membership = Activation.create! player: player, contract: contract, campaign: first_campaign
    contract.destroy!

    expect(membership.reload.contract).to be_nil
    expect(first_campaign.reload.activated_players).to match_array([player])
  end

  it "rejects a known athlete sport that differs from the campaign sport" do
    other_player = create :player, team: nil, sport: create(:football)
    membership = Activation.new player: other_player, campaign: first_campaign

    expect(membership).not_to be_valid
    expect(membership.errors[:player]).to include("must belong to the campaign's sport")
  end

  it "allows membership when an independent athlete sport has not been established" do
    other_player = create :player, team: nil, sport: nil
    expect(Activation.new(player: other_player, campaign: first_campaign)).to be_valid
  end

  it "accepts missing roster dates and rejects a reversed supplied interval" do
    membership = Activation.new player: player, campaign: first_campaign
    expect(membership).to be_valid

    membership.assign_attributes start_date: Date.new(2024, 10, 1), end_date: Date.new(2024, 9, 30)
    expect(membership).not_to be_valid
    expect(membership.errors[:end_date]).to be_present
  end
end
