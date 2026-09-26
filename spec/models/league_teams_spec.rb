require 'rails_helper'

RSpec.describe "League and sport teams" do
  it "includes teams that have no division membership" do
    team = create(:team)
    expect(team.league.teams).to eq([team])
    expect(team.league.sport.teams).to eq([team])
  end

  it "lists a team once even with several memberships" do
    team = create(:team)
    create(:membership, team: team, active: false)
    create(:membership, team: team, active: true)
    expect(team.league.teams.to_a).to eq([team])
  end
end
