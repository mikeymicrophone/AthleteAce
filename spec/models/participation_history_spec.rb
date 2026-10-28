require "rails_helper"

RSpec.describe "Organization contracts and participation history", type: :model do
  let(:league) { create :nba }
  let(:team) { create :team, league: league }
  let(:other_team) { create :team, league: league }
  let(:player) { create :player, team: nil, sport: league.sport }
  let(:other_player) { create :player, team: nil, sport: league.sport }
  let(:organization) { create :organization }
  let(:contract) { Contract.create! player: player, organization: organization }
  let(:season) { create :season, league: league }
  let(:campaign) { Campaign.create! team: team, season: season }
  let(:game) { Contest.create! context: league, kind: "game", begin_date: Date.new(2025, 10, 20) }
  let(:contestant) { Contestant.create! contest: game, campaign: campaign }
  let(:stint) { Stint.create! player: player, team: team, start_date: Date.new(2025, 10, 1), end_date: Date.new(2025, 10, 31) }
  let(:roster) { Roster.create! campaign: campaign, kind: "active", effective_on: Date.new(2025, 10, 20), coverage: "partial" }

  it "requires an organization even when a legacy team is supplied" do
    expect(contract.team).to be_nil
    expect(organization.contract_players).to contain_exactly(player)
    expect(Contract.new(player: player, team: team)).not_to be_valid
  end

  it "preserves an organization contract when its optional legacy team is removed" do
    contract.update! team: team
    team.destroy!
    expect(contract.reload.team).to be_nil
    expect(contract.organization).to eq(organization)
  end

  it "allows borrowed-team assignments and separate returns without fabricating dates" do
    first = Stint.create! player: player, team: other_team, contract: contract
    second = Stint.create! player: player, team: other_team, contract: contract
    expect(first).not_to eq(second)
    expect([ first.start_date, first.end_date ]).to eq([ nil, nil ])
    expect(first.contract.organization).to eq(organization)
  end

  it "rejects a stint's wrong-player contract, reversed dates, and wrong sport" do
    assignment = Stint.new player: other_player, team: team, contract: contract
    expect(assignment).not_to be_valid
    expect(assignment.errors[:contract]).to be_present
    assignment.assign_attributes contract: nil, start_date: Date.new(2025, 10, 20), end_date: Date.new(2025, 10, 19)
    expect(assignment).not_to be_valid
    assignment.assign_attributes start_date: nil, end_date: nil, player: create(:player, team: nil, sport: create(:hockey))
    expect(assignment).not_to be_valid
    expect(assignment.errors[:player]).to be_present
  end

  it "records a roster listing independently of a stint or game appearance" do
    entry = RosterEntry.create! roster: roster, player: player, jersey_number: "00"
    expect(entry.stint).to be_nil
    expect(entry.jersey_number).to eq("00")
    expect(roster.players).to contain_exactly(player)
    expect(Appearance.count).to eq(0)
  end

  it "checks a roster entry's linked stint player, team, and known date" do
    expect(RosterEntry.new(roster: roster, player: player, stint: stint)).to be_valid
    expect(RosterEntry.new(roster: roster, player: other_player, stint: stint)).not_to be_valid
    different_team = Stint.create! player: player, team: other_team
    expect(RosterEntry.new(roster: roster, player: player, stint: different_team)).not_to be_valid
    roster.effective_on = Date.new(2025, 11, 1)
    expect(RosterEntry.new(roster: roster, player: player, stint: stint)).not_to be_valid
  end

  it "does not treat an observation time as an effective assignment date" do
    roster.update! effective_on: nil, observed_at: Time.utc(2026, 1, 1)
    expect(RosterEntry.new(roster: roster, player: player, stint: stint)).to be_valid
  end

  it "rejects duplicate listings within one observation and permits another observation" do
    RosterEntry.create! roster: roster, player: player
    expect(RosterEntry.new(roster: roster, player: player)).not_to be_valid
    another = Roster.create! campaign: campaign, kind: "active", effective_on: roster.effective_on
    expect(RosterEntry.new(roster: another, player: player)).to be_valid
  end

  it "requires a game for appearances and preserves unknown starter status" do
    appearance = Appearance.create! player: player, contestant: contestant, stint: stint, statistics: { "points" => 4 }
    expect(appearance.starter).to be_nil
    expect(appearance.team).to eq(team)
    game.kind = "series"
    expect(game).not_to be_valid
    aggregate = Contest.create! context: league, kind: "series"
    participant = Contestant.create! contest: aggregate, campaign: campaign
    expect(Appearance.new(player: player, contestant: participant)).not_to be_valid
  end

  it "checks appearances against the assignment's player, team, and known date" do
    expect(Appearance.new(player: other_player, contestant: contestant, stint: stint)).not_to be_valid
    assignment = Stint.create! player: player, team: other_team
    expect(Appearance.new(player: player, contestant: contestant, stint: assignment)).not_to be_valid
    stint.end_date = Date.new(2025, 10, 19)
    expect(Appearance.new(player: player, contestant: contestant, stint: stint)).not_to be_valid
  end

  it "permits two games on the same date but rejects duplicate participation in a game" do
    Appearance.create! player: player, contestant: contestant
    expect(Appearance.new(player: player, contestant: contestant)).not_to be_valid
    second_game = Contest.create! context: league, kind: "game", begin_date: game.begin_date
    second_participant = Contestant.create! contest: second_game, campaign: campaign
    expect(Appearance.new(player: player, contestant: second_participant)).to be_valid
  end

  it "protects linked history when stint dates or game dates change" do
    Appearance.create! player: player, contestant: contestant, stint: stint
    stint.end_date = Date.new(2025, 10, 19)
    expect(stint).not_to be_valid
    game.begin_date = Date.new(2025, 11, 1)
    expect(game).not_to be_valid
  end

  it "protects linked history when roster or contestant context changes" do
    RosterEntry.create! roster: roster, player: player, stint: stint
    Appearance.create! player: player, contestant: contestant, stint: stint
    other_campaign = Campaign.create! team: other_team, season: season
    roster.campaign = other_campaign
    expect(roster).not_to be_valid
    contestant.campaign = other_campaign
    expect(contestant).not_to be_valid
  end

  it "keeps participation when its optional contract or stint is removed" do
    stint.update! contract: contract
    entry = RosterEntry.create! roster: roster, player: player, stint: stint
    appearance = Appearance.create! player: player, contestant: contestant, stint: stint
    contract.destroy!
    expect(stint.reload.contract).to be_nil
    stint.destroy!
    expect(entry.reload.stint).to be_nil
    expect(appearance.reload.stint).to be_nil
  end

  it "records a multi-player transaction without changing assignments automatically" do
    event = Transaction.create! kind: "trade", effective_on: Date.new(2025, 10, 20)
    TransactionPlayer.create! event: event, player: player, from_team: team, to_team: other_team
    TransactionPlayer.create! event: event, player: other_player, from_team: other_team, to_team: team
    expect(event.players).to match_array([ player, other_player ])
    expect(TransactionPlayer.new(event: event, player: player)).not_to be_valid
    expect(Stint.count).to eq(0)
  end

  it "keeps an event independent from stint lifecycle" do
    event = Transaction.create! kind: "loan"
    stint.update! start_transaction: event
    event.destroy!
    expect(stint.reload.start_transaction).to be_nil
  end

  it "rejects nonsensical coverage and metadata" do
    roster.coverage = "all_players_ever"
    expect(roster).not_to be_valid
    expect(Transaction.new(kind: "trade", source: "unsourced")).not_to be_valid
    expect(Appearance.new(player: player, contestant: contestant, statistics: [])).not_to be_valid
  end
end
