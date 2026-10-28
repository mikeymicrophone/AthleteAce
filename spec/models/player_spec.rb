require "rails_helper"

RSpec.describe Player, type: :model do
  it "keeps a retired or free-agent player's independent sport without a current team" do
    sport = create :basketball
    player = create :player, team: nil, sport: sport, active: false

    expect(player.reload.sport).to eq(sport)
    expect(player.team).to be_nil
    expect(player.league).to be_nil
    expect(player.current_organization).to be_nil
  end

  it "uses the current team's sport for legacy players without an independent sport" do
    team = create :team
    player = create :player, team: team, sport: nil

    expect(player.reload.sport).to eq(team.sport)
  end

  it "prefers the independently assigned sport over the current team fallback" do
    player = build :player, sport: build(:sport)
    expect(player.sport).not_to eq(player.team.sport)
    expect(player.sport).to eq(player.association(:sport).target)
  end
end
