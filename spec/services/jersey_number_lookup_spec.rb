require "rails_helper"

RSpec.describe JerseyNumberLookup do
  let(:team) { create(:team) }
  let(:player) { create(:player, team: team) }
  let(:season) { create(:season, league: team.league, start_date: "2024-10-01", end_date: "2025-04-30") }

  def assign(number, **attributes)
    JerseyNumberAssignment.create!(player: player, team: team, number: number, **attributes)
  end

  def lookup(**attributes)
    described_class.new(player: player, team: team, **attributes).call
  end

  def observation(number, on: nil)
    campaign = Campaign.find_or_create_by!(team: team, season: season)
    roster = Roster.create!(campaign: campaign, kind: "roster", effective_on: on)
    RosterEntry.create!(player: player, roster: roster, jersey_number: number)
  end

  it "resolves the exact day of a change, respects the team, and carries a number across seasons" do
    assign("00", start_date: "2023-01-01", end_date: "2025-01-14")
    assign("7", start_date: "2025-01-15")
    expect(lookup(on: Date.new(2025, 1, 14)).number).to eq("00")
    expect(lookup(on: Date.new(2025, 1, 15)).number).to eq("7")
    expect(lookup(on: Date.new(2026, 1, 15)).number).to eq("7")
    expect(lookup(team: create(:team, league: team.league))).to be_nil
    expect(lookup(on: Date.new(2022, 1, 15))).to be_nil
    expect(lookup(season: season)).to be_nil
  end

  it "shows a stable assignment only when it covers the dated season including playoffs" do
    assign("3", start_date: "2023-01-01", end_date: "2025-05-01")
    expect(lookup(season: season).number).to eq("3")
    season.update!(playoff_start_date: "2025-05-01", playoff_end_date: "2025-06-01")
    expect(lookup(season: season)).to be_nil
    season.update!(start_date: nil, end_date: nil, playoff_start_date: nil, playoff_end_date: nil)
    expect(lookup(season: season)).to be_nil
  end

  it "uses seasonal observations without turning them into permanent assignments" do
    observation("3", on: "2025-01-02")
    result = lookup(season: season)
    expect(result.number).to eq("3")
    expect(result.observed_on).to eq(Date.new(2025, 1, 2))
    expect(lookup(on: Date.new(2025, 1, 2)).number).to eq("3")
    expect(lookup(on: Date.new(2025, 1, 3))).to be_nil
    expect(JerseyNumberAssignment.count).to eq(0)
    observation("7", on: "2025-01-15")
    expect(lookup(season: season)).to be_nil
  end

  it "uses an explicitly unbounded assignment even when the season dates are unknown" do
    assign("00")
    season.update!(start_date: nil, end_date: nil)
    expect(lookup(season: season).number).to eq("00")
  end

  it "uses a club's number history in another competition with a recorded campaign" do
    competition = create(:league, sport: team.sport)
    cup_season = create(:season, league: competition, start_date: "2024-10-01", end_date: "2025-04-30")
    assign("3", start_date: "2023-01-01")
    expect(lookup(season: cup_season)).to be_nil
    Campaign.create!(team: team, season: cup_season)
    expect(lookup(season: cup_season).number).to eq("3")
  end

  it "withholds conflicting assignment and observation evidence" do
    assign("00", start_date: "2023-01-01")
    observation("7", on: "2025-01-02")
    expect(lookup(season: season)).to be_nil
    expect(lookup(on: Date.new(2025, 1, 2))).to be_nil
  end

  it "uses a game appearance only for its known day or recorded season" do
    campaign = Campaign.create!(team: team, season: season)
    game = Contest.create!(kind: "game", context: team.league, season: season, begin_date: "2025-01-02")
    contestant = Contestant.create!(contest: game, campaign: campaign)
    Appearance.create!(player: player, contestant: contestant, jersey_number: "00")
    expect(lookup(on: Date.new(2025, 1, 2)).number).to eq("00")
    expect(lookup(on: Date.new(2025, 1, 3))).to be_nil
    expect(lookup(season: season).observed_on).to eq(Date.new(2025, 1, 2))
    other = create(:season, league: team.league)
    expect(lookup(season: other)).to be_nil
  end
end
