require "rails_helper"

RSpec.describe GameRoundSetup do
  let(:ace) { create(:ace) }
  let(:league) { create(:league) }
  let!(:team) { create(:team, league: league) }
  let!(:other_team) { create(:team, league: league) }
  let!(:player) { create(:player, team: team, active: true) }

  it "chooses and saves a fixed question list, repeating a small pool and keeping choices in the league" do
    create(:player, team: other_team, active: false)
    create(:player)
    setup = described_class.new game_type: "player_team_match", league_id: league.id, length: 20
    expect(setup.available_count).to eq(1)
    round = setup.start! ace
    expect(round.questions.size).to eq(20)
    expect(round.questions.map { |q| q.fetch("subject_id") }.uniq).to eq([player.id])
    expect(round.questions.flat_map { |q| q.fetch("choices").map { |c| c.fetch("id") } }.uniq).to match_array([team.id, other_team.id])
    expect(round.reload.questions).to eq(round.questions)
    expect(round.scope["length"]).to eq(20)
    expect(described_class.new(league_id: league.id, include_inactive: true).available_count).to eq(2)
  end

  it "keeps explicit pair drills focused and allows unclassified active status" do
    third = create(:team, league: league)
    create(:player, team: third)
    create(:player, team: other_team, active: nil)
    setup = described_class.new team_ids: [team.id.to_s, other_team.id.to_s]
    expect(setup.available_count).to eq(2)
    expect(setup.start!(ace).questions.flat_map { |q| q.fetch("choices").map { |c| c.fetch("id") } }.uniq).to match_array([team.id, other_team.id])
  end

  it "builds division questions only for teams with a playable division in the chosen scope" do
    conference = create(:conference, league: league)
    divisions = create_list(:division, 2, conference: conference)
    create(:membership, team: team, division: divisions.first)
    create(:membership, team: other_team, division: divisions.last)
    setup = described_class.new game_type: "guess_the_division", team_id: team.id
    expect(setup.available_count).to eq(1)
    round = setup.start! ace
    expect(round.questions.map { |q| q.fetch("subject_id") }.uniq).to eq([team.id])
    expect(round.questions.map { |q| q.fetch("target_id") }.uniq).to eq([divisions.first.id])
    expect(round.questions.flat_map { |q| q.fetch("choices").map { |c| c.fetch("id") } }.uniq).to match_array(divisions.map(&:id))
  end

  it "rejects unsupported games, lengths, incompatible filters, and missing or duplicate drill teams" do
    [
      { game_type: "invented" }, { length: 11 }, { team_id: -1 },
      { sport_id: create(:sport).id, league_id: league.id },
      { team_ids: [team.id, -1] }, { team_ids: [team.id, team.id] }
    ].each do |params|
      expect { described_class.new(params).start! ace }.to raise_error(ActiveModel::ValidationError)
    end
    expect(ace.game_rounds).to be_empty
  end

  it "reports empty scopes without substituting unrelated questions" do
    expect { described_class.new(team_id: other_team.id).start! ace }.to raise_error(ActiveModel::ValidationError, /No playable questions/)
    expect { described_class.new(game_type: "guess_the_division").start! ace }.to raise_error(ActiveModel::ValidationError)
  end
end
