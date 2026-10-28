require "rails_helper"

RSpec.describe "Player group practice" do
  let(:ace) { create(:ace) }
  let(:league) { create(:league) }
  let!(:team) { create(:team, league: league) }
  let!(:rival) { create(:team, league: league) }
  let!(:jalen) { create(:player, first_name: "Jalen", last_name: "Brunson", team: team, photo_urls: [ "/jalen.png" ]) }
  let!(:josh) { create(:player, first_name: "Josh", last_name: "Hart", team: rival, active: false, photo_urls: [ "/josh.png" ]) }
  let!(:outsider) { create(:player, team: team, photo_urls: [ "/other.png" ]) }
  let(:group) { PlayerGroup.create!(name: "Names to learn", players: [ jalen, josh ]) }

  def setup(mode, **filters)
    GameRoundSetup.new({ player_group_id: group.id, game_type: mode }.merge(filters))
  end

  %w[player_team_match name_ciphers multiple_choice image_recognition].each do |mode|
    it "limits #{mode} to group members including inactive players" do
      round = setup(mode).start!(ace)
      expect(round.questions.map { |question| question.fetch("subject_id") }).to match_array([ jalen.id, josh.id ])
      expect(round.scope.fetch("player_group_id")).to eq(group.id)
      expect(round.scope_label).to include(group.name)
    end
  end

  it "uses group members without current teams for name and birth-fact games" do
    countries = create_list(:country, 2)
    jalen.update!(team: nil, birth_country: countries.first)
    josh.update!(team: nil, birth_country: countries.last)
    expect(setup("name_ciphers").available_count).to eq(2)
    expect(setup("image_recognition").available_count).to eq(2)
    round = setup("multiple_choice", fact_type: "birth_country").start!(ace)
    expect(round.questions.map { |question| question.fetch("subject_id") }).to match_array([ jalen.id, josh.id ])
  end

  it "intersects groups with team filters and does not expand empty or invalid groups" do
    expect(setup("player_team_match", team_id: team.id).subjects.pluck(:id)).to eq([ jalen.id ])
    empty = PlayerGroup.create!(name: "Future names")
    expect(GameRoundSetup.new(player_group_id: empty.id).available_count).to eq(0)
    invalid = GameRoundSetup.new(player_group_id: -1)
    expect(invalid.available_count).to eq(0)
    expect { invalid.start!(ace) }.to raise_error(ActiveModel::ValidationError)
  end

  it "uses group membership for seasonal facts even without current teams" do
    season = create(:season, league: league)
    [ jalen, josh, outsider ].each do |player|
      Activation.create!(player: player, campaign: Campaign.create!(team: player.team, season: season)) unless player == outsider
      player.update!(team: nil)
    end
    expect(setup("player_team_match", season_id: season.id).subjects.pluck(:id)).to match_array([ jalen.id, josh.id ])
    expect(setup("multiple_choice", season_id: season.id).available_count).to eq(2)
    expect(setup("name_ciphers", season_id: season.id, player_id: jalen.id).available_count).to eq(0)
    expect(setup("multiple_choice", season_id: season.id, player_id: jalen.id).available_count).to eq(0)
  end

  it "reviews only due questions for members of the selected group" do
    round = GameRoundSetup.new(team_id: team.id).start!(ace)
    round.questions.each_with_index do |question, index|
      round.answer!(at: index, choice_id: nil)
      round.advance!(at: index)
    end
    ace.practice_reviews.update_all(due_at: 1.minute.ago)
    review = setup("phased_repetition").start!(ace)
    expect(review.questions.map { |question| question.fetch("subject_id") }).to eq([ jalen.id ])
  end

  it "asks divisions for members' teams without pulling in unrelated teams" do
    conference = create(:conference, league: league)
    divisions = create_list(:division, 2, conference: conference)
    team.update!(division: divisions.first)
    rival.update!(division: divisions.last)
    create(:team, league: league, division: divisions.first)
    round = setup("guess_the_division").start!(ace)
    expect(round.questions.map { |question| question.fetch("subject_id") }).to match_array([ team.id, rival.id ])
  end

  it "snapshots group quest members and completes only after each has one correct answer" do
    quest = create(:quest)
    achievement = create(:achievement, target: group)
    create(:highlight, quest: quest, achievement: achievement)
    goal = create(:goal, ace: ace, quest: quest)
    group.players << outsider
    group.players.delete(jalen)
    entry = goal.goal_achievements.sole
    expect(entry.required_player_ids).to match_array([ jalen.id, josh.id ])
    round = setup("player_team_match", goal_achievement_id: entry.id).start!(ace)
    expect(round.questions.map { |question| question.fetch("subject_id") }).to match_array([ jalen.id, josh.id ])
    round.questions.each_with_index do |question, index|
      round.answer!(at: index, choice_id: question.fetch("target_id"))
      round.advance!(at: index)
    end
    expect(entry.reload.player_ids).to match_array([ jalen.id, josh.id ])
    expect(goal.reload.status).to eq("completed")
  end

  it "preserves a saved round after group membership changes" do
    round = setup("name_ciphers").start!(ace)
    questions = round.questions
    group.players.delete(jalen)
    group.destroy!
    expect(round.reload.questions).to eq(questions)
    expect { round.answer!(at: 0, choice_id: round.question.fetch("target_id")) }.to change(GameAttempt, :count).by(1)
  end
  it "keeps the account context when suggesting a season for an adopted group" do
    season = create(:season, league: league)
    [ jalen, josh ].each do |player|
      Activation.create!(player: player, campaign: Campaign.create!(team: player.team, season: season))
      player.update!(team: nil)
    end
    quest = create(:quest)
    create(:highlight, quest: quest, achievement: create(:achievement, target: group))
    entry = create(:goal, ace: ace, quest: quest).goal_achievements.sole

    suggestion = setup("player_team_match", ace: ace, goal_achievement_id: entry.id).season_suggestion

    expect(suggestion.season_id).to eq(season.id)
    expect(suggestion.available_count).to eq(2)
    expect(suggestion.scope_params.fetch("goal_achievement_id")).to eq(entry.id)
  end

  it "does not expose another account's adopted group roster" do
    quest = create(:quest)
    achievement = create(:achievement, target: group)
    create(:highlight, quest: quest, achievement: achievement)
    goal = create(:goal, ace: ace, quest: quest)
    selected = setup("name_ciphers", goal_achievement_id: goal.goal_achievements.sole.id)
    expect { selected.start!(create(:ace)) }.to raise_error(ActiveModel::ValidationError)
    expect(selected.available_count).to eq(0)
  end
end
