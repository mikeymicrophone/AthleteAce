require "rails_helper"

RSpec.describe "Seasonal round setup" do
  let(:ace) { create(:ace) }
  let(:league) { create(:league) }
  let(:season) { create(:season, league: league, label: "2025–26") }
  let(:other_season) { create(:season, league: league, label: "2024–25") }
  let(:knicks) { create(:team, league: league, territory: "New York", mascot: "Knicks") }
  let(:nets) { create(:team, league: league, territory: "Brooklyn", mascot: "Nets") }
  let(:third) { create(:team, league: league) }

  def membership(player, team, in_season = season)
    campaign = Campaign.find_or_create_by!(team: team, season: in_season)
    Activation.create!(player: player, campaign: campaign)
  end

  def setup(**params)
    GameRoundSetup.new(season_id: season.id, team_ids: [ knicks.id, nets.id ], **params)
  end

  it "uses the chosen season instead of current team and inactive status" do
    old_knick = create(:player, team: third, active: false, current_position: "Current position")
    knicks.update!(primary_color: "#006BB6")
    net = create(:player, team: nil, active: false)
    membership(old_knick, knicks)
    membership(net, nets)
    membership(old_knick, nets, other_season)
    expect(setup.available_count).to eq(2)
    round = setup.start!(ace)
    expect(round.scope.fetch("season_id")).to eq(season.id)
    expect(round.scope_label).to include("2025–26")
    expect(round.questions.map { |q| [ q.fetch("subject_id"), q.fetch("target_id") ] }.uniq).to match_array([ [ old_knick.id, knicks.id ], [ net.id, nets.id ] ])
    expect(round.questions.all? { |q| q.fetch("season_name") == season.name }).to be(true)
    snapshot = round.questions.deep_dup
    old_question = snapshot.find { |question| question.fetch("subject_id") == old_knick.id }
    expect(old_question.fetch("subject_primary_color")).to eq("#006BB6")
    expect(old_question).not_to have_key("subject_position")
    knicks.update!(territory: "Changed territory", primary_color: "#FFFFFF")
    expect(old_question.fetch("choices").find { |choice| choice.fetch("id") == knicks.id }).to include(
      "territory" => "New York", "mascot" => "Knicks", "primary_color" => "#006BB6"
    )
    membership(old_knick, nets)
    old_knick.update!(team: nil)
    round.answer!(at: 0, choice_id: round.question.fetch("target_id"))
    expect(round.current_attempt).to be_correct
    expect(round.reload.questions).to eq(snapshot)
    expect(old_knick.reload.team_id).to be_nil
    expect(net.reload.team_id).to be_nil
  end

  it "excludes same-season ambiguity across all teams, even outside the selected scope" do
    player = create(:player, team: nil)
    membership(player, knicks)
    membership(player, third)
    Campaign.create!(team: nets, season: season)
    expect(setup.available_count).to eq(0)
    expect(setup.season_pool.ambiguous_count).to eq(1)
    expect { setup.start!(ace) }.to raise_error(ActiveModel::ValidationError, /No playable questions/)
  end

  it "uses roster-only observations and deduplicates overlapping membership facts" do
    skip "Optional roster catalog tables are not installed" unless ApplicationRecord.connection.data_source_exists?("roster_entries")
    player = create(:player, team: nil)
    campaign = Campaign.create!(team: knicks, season: season)
    Campaign.create!(team: nets, season: season)
    roster = Roster.create!(campaign: campaign, kind: "roster", coverage: "partial")
    RosterEntry.create!(roster: roster, player: player)
    expect(setup.available_count).to eq(1)
    membership(player, knicks)
    expect(setup.available_count).to eq(1)
    expect(setup.season_pool.ambiguous_count).to eq(0)
  end

  it "suggests a playable recorded season without changing the selected teams or current mode" do
    player = create(:player, team: nil)
    membership(player, knicks)
    Campaign.create!(team: nets, season: season)
    current = GameRoundSetup.new(league_id: league.id, team_ids: [ knicks.id, nets.id ], length: 20)
    suggestion = current.season_suggestion
    expect(suggestion.season).to eq(season)
    expect(suggestion.selected_team_ids).to match_array([ knicks.id, nets.id ])
    expect(suggestion.length).to eq(20)
    expect(suggestion.available_count).to eq(1)
    expect(current.season_id).to be_nil
    expect(current.available_count).to eq(0)
  end

  it "rejects a season outside the chosen league and unsupported historical division games" do
    Campaign.create!(team: knicks, season: season)
    Campaign.create!(team: nets, season: season)
    invalid = setup(league_id: create(:league).id)
    expect(invalid).not_to be_valid
    expect(invalid.errors[:season]).to include("is outside the selected league")
    expect(setup(game_type: "guess_the_division")).not_to be_valid
    expect(GameRoundSetup.new(season_id: -1)).not_to be_valid
  end
end
