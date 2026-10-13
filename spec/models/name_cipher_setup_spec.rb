require "rails_helper"

RSpec.describe "Name Cipher setup" do
  let(:ace) { create(:ace) }
  let(:team) { create(:team) }
  let!(:first) { create(:player, team: team, first_name: "Aaron", last_name: "Judge", active: true) }
  let!(:second) { create(:player, team: team, first_name: "José", last_name: "O’Neal-Smith", active: true) }

  it "keeps puzzles, letters and distinct name choices inside the selected scope" do
    create(:player, team: team, first_name: "Aaron", last_name: "Judge", active: true)
    create(:player, team: team, active: false)
    outsider = create(:player, active: true)
    setup = GameRoundSetup.new(game_type: "name_ciphers", team_ids: [ team.id ], length: 20)
    expect(setup.available_count).to eq(2)
    round = setup.start!(ace)
    expect(round.questions.size).to eq(20)
    round.questions.each do |question|
      expect(question.fetch("subject_id")).to eq(question.fetch("target_id"))
      expect(question.fetch("choices").map { |choice| choice.fetch("id") }).to match_array([ first.id, second.id ])
      expect(question.fetch("choices").map { |choice| choice.fetch("id") }).not_to include(outsider.id)
      expect(question.fetch("scrambled_name").chars.sort).to eq(question.fetch("subject_name").upcase.chars.sort)
      expect(question.fetch("scrambled_name")).not_to eq(question.fetch("subject_name").upcase)
      expect(question.fetch("team_id")).to eq(team.id)
    end
    expect(round.reload.questions).to eq(round.questions)
  end

  it "allows unassigned players without a team filter, but requires two distinct names" do
    first.update!(team: nil)
    second.update!(team: nil)
    expect(GameRoundSetup.new(game_type: "name_ciphers").available_count).to eq(2)
    expect(GameRoundSetup.new(game_type: "name_ciphers", team_id: team.id).available_count).to eq(0)
    second.update!(first_name: first.first_name, last_name: first.last_name)
    expect { GameRoundSetup.new(game_type: "name_ciphers").start!(ace) }.to raise_error(ActiveModel::ValidationError, /No playable questions/)
  end

  it "uses a single selected season roster even when today's team and active status differ" do
    season = create(:season, league: team.league)
    campaign = Campaign.create!(team: team, season: season)
    [ first, second ].each do |player|
      Activation.create!(player: player, campaign: campaign)
      player.update!(team: nil, active: false)
    end
    setup = GameRoundSetup.new(game_type: "name_ciphers", season_id: season.id, team_ids: [ team.id ])
    expect(setup.available_count).to eq(2)
    round = setup.start!(ace)
    expect(round.scope.fetch("season_id")).to eq(season.id)
    expect(round.questions.map { |question| question.fetch("season_name") }.uniq).to eq([ season.name ])
    expect(round.questions.map { |question| question.fetch("team_id") }.uniq).to eq([ team.id ])
    expect(round.questions.map { |question| question.fetch("team_name") }.uniq).to eq([ team.name ])
  end
end
