require "rails_helper"

RSpec.describe "Quick round team preferences", type: :request do
  let(:ace) { create(:ace) }
  let!(:team) { create(:team) }
  let!(:rival) { create(:team, league: team.league) }
  let!(:players) { create_list(:player, 2, team: team) }
  let!(:others) { create_list(:player, 2, team: rival) }

  before { sign_in ace }

  it "uses followed teams and ignores posted preferences and other accounts" do
    ace.follows.create!(followable: team)
    create(:ace).follows.create!(followable: rival)
    post play_quick_path, params: { team_ids: [ rival.id ] }
    round = ace.game_rounds.last
    expect(response).to redirect_to(game_round_path(round))
    expect(round.questions.map { |q| q.fetch("subject_id") }).to match_array(players.map(&:id))
  end

  it "uses approved active high Affinity ratings at the 5000 threshold" do
    affinity = create(:spectrum, name: "Affinity")
    create(:rating, ace: ace, target: team, spectrum: affinity, value: 5000)
    create(:rating, ace: ace, target: rival, spectrum: affinity, value: 4999)
    post play_quick_path
    expect(ace.game_rounds.last.questions.map { |q| q.fetch("subject_id") }).to match_array(players.map(&:id))
  end

  it "falls back to the general pool for empty followed teams" do
    ace.follows.create!(followable: create(:team, league: team.league))
    post play_quick_path
    round = ace.game_rounds.last
    expect(response).to redirect_to(game_round_path(round))
    expect(round.questions.map { |q| q.fetch("subject_id") }).to match_array((players + others).map(&:id))
  end

  it "uses a followed team's recorded season before unrelated current players" do
    historical_team = create(:team, league: team.league)
    season = create(:season, league: team.league)
    campaign = Campaign.create!(team: historical_team, season: season)
    historical_player = create(:player, team: nil, active: false)
    Activation.create!(player: historical_player, campaign: campaign)
    other_campaign = Campaign.create!(team: rival, season: season)
    Activation.create!(player: others.first, campaign: other_campaign)
    ace.follows.create!(followable: historical_team)
    post play_quick_path
    round = ace.game_rounds.last
    expect(response).to redirect_to(game_round_path(round))
    expect(round.scope.fetch("season_id")).to eq(season.id)
    expect(round.questions.map { |q| q.fetch("subject_id") }).to eq([ historical_player.id ])
  end

  it "ignores archived ratings and unapproved Affinity spectrums" do
    affinity = create(:spectrum, name: "Affinity", moderation_status: "hidden")
    create(:rating, ace: ace, target: team, spectrum: affinity, value: 10_000)
    post play_quick_path
    expect(ace.game_rounds.last.questions.map { |q| q.fetch("subject_id") }).to match_array((players + others).map(&:id))
    affinity.update!(moderation_status: "approved")
    ace.ratings.update_all(archived: true)
    post play_quick_path
    expect(ace.game_rounds.last.questions.map { |q| q.fetch("subject_id") }).to match_array((players + others).map(&:id))
  end

  it "keeps recent misses ahead of followed teams" do
    ace.follows.create!(followable: team)
    create(:game_attempt, ace: ace, subject_entity: others.first, is_correct: false)
    post play_quick_path
    round = ace.game_rounds.last
    expect(round.questions.map { |q| q.fetch("subject_id") }).to eq([ others.first.id ])
  end

  it "keeps due reviews ahead of followed teams" do
    ace.follows.create!(followable: team)
    original = GameRoundSetup.new(team_id: rival.id).start!(ace)
    original.answer!(at: 0, choice_id: nil)
    ace.practice_reviews.update_all(due_at: 1.minute.ago)
    post play_quick_path
    expect(ace.game_rounds.last.game_type).to eq("phased_repetition")
    expect(ace.game_rounds.last.question.fetch("subject_id")).to be_in(others.map(&:id))
  end
end
