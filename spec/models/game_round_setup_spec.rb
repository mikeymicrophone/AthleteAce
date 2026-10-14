require "rails_helper"

RSpec.describe GameRoundSetup do
  let(:ace) { create(:ace) }
  let(:league) { create(:league) }
  let!(:team) { create(:team, league: league) }
  let!(:other_team) { create(:team, league: league) }
  let!(:player) { create(:player, team: team, active: true) }

  it "shortens a small pool without repeating names and keeps choices in the league" do
    create(:player, team: other_team, active: false)
    create(:player)
    setup = described_class.new game_type: "player_team_match", league_id: league.id, length: 20
    expect(setup.available_count).to eq(1)
    round = setup.start! ace
    expect(round.questions.size).to eq(1)
    expect(round.length).to eq(1)
    expect(setup.question_count).to eq(1)
    expect(round.questions.map { |q| q.fetch("subject_id") }.uniq).to eq([ player.id ])
    expect(round.questions.flat_map { |q| q.fetch("choices").map { |c| c.fetch("id") } }.uniq).to match_array([ team.id, other_team.id ])
    expect(round.reload.questions).to eq(round.questions)
    expect(round.scope["length"]).to eq(20)
    expect(described_class.new(league_id: league.id, include_inactive: true).available_count).to eq(2)
  end

  it "spreads questions across selected teams without repeating players when coverage is uneven" do
    create_list(:player, 17, team: team, active: true)
    [ other_team, create(:team, league: league), create(:team, league: league) ].each do |club|
      create_list(:player, 2, team: club, active: true)
    end
    setup = described_class.new(team_ids: league.teams.pluck(:id))
    round = setup.start!(ace)
    expect(round.questions.map { |question| question.fetch("subject_id") }.uniq.size).to eq(10)
    expect(round.questions.map { |question| question.fetch("target_id") }.tally.values.sort).to eq([ 2, 2, 2, 4 ])
    expect(setup.pool_coverage.map { |entry| entry.fetch(:count) }.sort).to eq([ 2, 2, 2, 18 ])
  end

  it "gives two selected teams five questions each when both have enough players" do
    create_list(:player, 5, team: team, active: true)
    create_list(:player, 6, team: other_team, active: true)
    round = described_class.new(team_ids: [ team.id, other_team.id ]).start!(ace)
    expect(round.questions.map { |question| question.fetch("target_id") }.tally).to eq(team.id => 5, other_team.id => 5)
  end

  it "snapshots stored palettes so later team edits cannot change a saved round" do
    team.update!(primary_color: "#006BB6", secondary_color: "#F58426")
    round = described_class.new(team_id: team.id).start!(ace)
    question = round.questions.first
    choice = question.fetch("choices").find { |entry| entry.fetch("id") == team.id }
    expect(question).to include("subject_primary_color" => "#006BB6", "subject_secondary_color" => "#F58426",
      "subject_text_color" => "#FFFFFF")
    expect(choice).to include("primary_color" => "#006BB6", "secondary_color" => "#F58426", "text_color" => "#FFFFFF")
    team.update!(primary_color: "#FFFFFF", secondary_color: "#000000")
    expect(round.reload.questions.first).to eq(question)
  end

  it "snapshots the current number and keeps old rounds independent of later number changes" do
    assignment = JerseyNumberAssignment.create!(player: player, team: team, number: "00", start_date: Date.current - 2.years)
    round = described_class.new(team_id: team.id).start!(ace)
    expect(round.questions.first["subject_jersey_number"]).to eq("00")
    assignment.update!(end_date: Date.current - 1.day)
    JerseyNumberAssignment.create!(player: player, team: team, number: "7", start_date: Date.current)
    expect(round.reload.questions.first["subject_jersey_number"]).to eq("00")
    expect(described_class.new(team_id: team.id).start!(ace).questions.first["subject_jersey_number"]).to eq("7")
  end

  it "keeps explicit pair drills focused and allows unclassified active status" do
    third = create(:team, league: league)
    create(:player, team: third)
    create(:player, team: other_team, active: nil)
    setup = described_class.new team_ids: [ team.id.to_s, other_team.id.to_s ]
    expect(setup.available_count).to eq(2)
    expect(setup.start!(ace).questions.flat_map { |q| q.fetch("choices").map { |c| c.fetch("id") } }.uniq).to match_array([ team.id, other_team.id ])
  end

  it "supports a single checked team with other teams in its league as answer choices" do
    setup = described_class.new(team_ids: [ team.id.to_s ])
    expect(setup.available_count).to eq(1)
    round = setup.start!(ace)
    expect(round.questions.map { |q| q.fetch("subject_id") }.uniq).to eq([ player.id ])
    expect(round.questions.flat_map { |q| q.fetch("choices").map { |c| c.fetch("id") } }.uniq).to match_array([ team.id, other_team.id ])
    expect(setup.team_options).to include(team, other_team)
  end

  it "keeps selected teams visible outside the current search and honors them over a legacy team id" do
    setup = described_class.new(team_id: other_team.id, team_ids: [ team.id.to_s ], team_query: other_team.mascot)
    expect(setup.team_options).to include(team, other_team)
    expect(setup.subjects).to contain_exactly(player)
    expect(setup.scope_label).to eq(team.name)
    expect(setup.scope_params).not_to have_key("team_id")
  end

  it "builds division questions only for teams with a playable division in the chosen scope" do
    conference = create(:conference, league: league)
    divisions = create_list(:division, 2, conference: conference)
    create(:membership, team: team, division: divisions.first)
    create(:membership, team: other_team, division: divisions.last)
    setup = described_class.new game_type: "guess_the_division", team_id: team.id
    expect(setup.available_count).to eq(1)
    round = setup.start! ace
    expect(round.questions.map { |q| q.fetch("subject_id") }.uniq).to eq([ team.id ])
    expect(round.questions.map { |q| q.fetch("target_id") }.uniq).to eq([ divisions.first.id ])
    expect(round.questions.flat_map { |q| q.fetch("choices").map { |c| c.fetch("id") } }.uniq).to match_array(divisions.map(&:id))
  end

  it "rejects unsupported games, lengths, incompatible filters, and missing or duplicate drill teams" do
    [
      { game_type: "invented" }, { length: 11 }, { team_id: -1 },
      { sport_id: create(:sport).id, league_id: league.id },
      { team_ids: [ team.id, -1 ] }, { team_ids: [ team.id, team.id ] }
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
