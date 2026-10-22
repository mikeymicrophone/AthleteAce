require "rails_helper"

RSpec.describe "Followed players in Quick rounds", type: :request do
  let(:ace) { create(:ace) }
  let!(:team) { create(:team) }
  let!(:rival) { create(:team, league: team.league) }
  let!(:player) { create(:player, team: team) }
  let!(:other) { create(:player, team: rival) }

  before { sign_in ace }

  it "practices followed players before followed teams without including teammates or posted players" do
    ace.follows.create!(followable: player)
    ace.follows.create!(followable: rival)
    create(:ace).follows.create!(followable: other)
    create(:player, team: team)
    post play_quick_path, params: { player_ids: [ other.id ] }
    round = ace.game_rounds.last
    expect(response).to redirect_to(game_round_path(round))
    expect(round.game_type).to eq("player_team_match")
    expect(round.questions.map { |q| q.fetch("subject_id") }).to eq([ player.id ])
    expect(round.scope.fetch("player_ids")).to eq([ player.id ])
    expect(ace.game_rounds.count).to eq(1)
  end

  it "includes deliberately followed inactive players with recorded current teams" do
    player.update!(active: false)
    ace.follows.create!(followable: player)
    post play_quick_path
    expect(ace.game_rounds.last.question.fetch("subject_id")).to eq(player.id)
  end

  it "uses an unassigned followed player's recorded season" do
    player.update!(team: nil, active: false)
    season = create(:season, league: team.league)
    campaign = Campaign.create!(team: team, season: season)
    other_campaign = Campaign.create!(team: rival, season: season)
    Activation.create!(player: player, campaign: campaign)
    Activation.create!(player: other, campaign: other_campaign)
    ace.follows.create!(followable: player)
    post play_quick_path
    round = ace.game_rounds.last
    expect(round.scope.fetch("season_id")).to eq(season.id)
    expect(round.question.fetch("subject_id")).to eq(player.id)
    expect(round.question.fetch("target_id")).to eq(team.id)
  end

  it "uses Name Ciphers for followed names without team data and preserves replay scope" do
    [ player, other ].each do |record|
      record.update!(team: nil, active: false)
      ace.follows.create!(followable: record)
    end
    post play_quick_path
    round = ace.game_rounds.last
    expect(round.game_type).to eq("name_ciphers")
    expect(round.questions.map { |q| q.fetch("subject_id") }).to match_array([ player.id, other.id ])
    round.questions.each_with_index do |question, position|
      round.answer!(at: position, choice_id: question.fetch("target_id"))
      round.advance!(at: position)
    end
    ace.follows.destroy_all
    get summary_game_round_path(round)
    link = Nokogiri::HTML(response.body).css("a").find { |node| node.text == "Play again" }
    query = Rack::Utils.parse_nested_query(URI.parse(link["href"]).query)
    expect(query.fetch("player_ids")).to match_array([ player.id.to_s, other.id.to_s ])
    expect(query.fetch("game_type")).to eq("name_ciphers")
  end

  it "falls back to preferred teams when a single followed name has no playable facts" do
    unassigned = create(:player, team: nil)
    ace.follows.create!(followable: unassigned)
    ace.follows.create!(followable: rival)
    post play_quick_path
    round = ace.game_rounds.last
    expect(round.game_type).to eq("player_team_match")
    expect(round.questions.map { |q| q.fetch("subject_id") }).to eq([ other.id ])
  end

  it "limits player preferences to the 30 most recent follows" do
    followed = create_list(:player, 31, team: team)
    followed.each { |record| ace.follows.create!(followable: record) }
    post play_quick_path
    round = ace.game_rounds.last
    expect(round.scope.fetch("player_ids")).to match_array(followed.last(30).map(&:id))
    expect(round.questions.size).to eq(10)
    expect(round.questions.map { |q| q.fetch("subject_id") }).not_to include(followed.first.id)
  end

  it "keeps due reviews ahead of followed players" do
    ace.follows.create!(followable: player)
    original = GameRoundSetup.new(team_id: rival.id).start!(ace)
    original.answer!(at: 0, choice_id: nil)
    ace.practice_reviews.update_all(due_at: 1.minute.ago)
    post play_quick_path
    round = ace.game_rounds.last
    expect(round.game_type).to eq("phased_repetition")
    expect(round.question.fetch("subject_id")).to eq(other.id)
  end

  it "keeps recent misses ahead of followed players" do
    ace.follows.create!(followable: player)
    create(:game_attempt, ace: ace, subject_entity: other, is_correct: false)
    post play_quick_path
    expect(ace.game_rounds.last.question.fetch("subject_id")).to eq(other.id)
  end
end
