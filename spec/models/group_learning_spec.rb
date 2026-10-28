require "rails_helper"

RSpec.describe "Group learning progress" do
  let(:ace) { create(:ace) }
  let(:league) { create(:league) }
  let!(:team) { create(:team, league: league) }
  let!(:rival) { create(:team, league: league) }
  let!(:jalen) { create(:player, first_name: "Jalen", last_name: "Brunson", team: team, photo_urls: [ "/icon.png" ]) }
  let!(:josh) { create(:player, first_name: "Josh", last_name: "Hart", team: rival, active: false, photo_urls: [ "/icon.png" ]) }
  let!(:outsider) { create(:player, team: team) }
  let(:group) { PlayerGroup.create!(name: "Knicks names", players: [ jalen, josh ]) }

  def answer(player, correct: true, **attributes)
    create(:game_attempt, ace: ace, subject_entity: player, is_correct: correct, **attributes)
  end

  def setup(mode, filter: "remaining", **attributes)
    GameRoundSetup.new({ game_type: mode, player_group_id: group.id, practice_filter: filter, ace: ace }.merge(attributes))
  end

  it "separates lifetime coverage, current recall and unpracticed members" do
    progress = PlayProgress.new(ace: ace, players: group.players)
    expect(progress.player_status(jalen.id)).to eq(:unpracticed)
    answer(jalen)
    progress = PlayProgress.new(ace: ace, players: group.players)
    expect(progress.correct_player_ids).to eq([ jalen.id ])
    expect(progress.known_player_ids).to be_empty
    expect(progress.player_status(jalen.id)).to eq(:correct)
    answer(jalen)
    expect(PlayProgress.new(ace: ace, players: group.players).player_status(jalen.id)).to eq(:known)
    answer(jalen, correct: false)
    progress = PlayProgress.new(ace: ace, players: group.players)
    expect(progress.correct_player_ids).to eq([ jalen.id ])
    expect(progress.known_player_ids).to be_empty
    expect(progress.missed_player_ids).to eq([ jalen.id ])
    expect(progress.player_status(jalen.id)).to eq(:missed)
  end

  it "excludes non-members, other accounts, future attempts and team-only questions" do
    answer(outsider)
    answer(jalen, created_at: 1.day.from_now)
    create(:game_attempt, subject_entity: josh, is_correct: true)
    create(:game_attempt, ace: ace, game_type: "guess_the_division", subject_entity: team, target_entity: create(:division))
    progress = PlayProgress.new(ace: ace, players: group.players)
    expect(progress.correct_player_ids).to be_empty
    expect(progress.missed_player_ids).to be_empty
    expect(progress.streaks[:current]).to eq(0)
  end

  %w[name_ciphers image_recognition multiple_choice player_team_match].each do |mode|
    it "can ask about the last remaining player in #{mode} without outside subjects or choices" do
      answer(jalen)
      round = setup(mode).start!(ace)
      expect(round.length).to eq(1)
      expect(round.question.fetch("subject_id")).to eq(josh.id)
      allowed = mode.in?(%w[name_ciphers image_recognition]) ? [ jalen.id, josh.id ] : [ team.id, rival.id ]
      expect(round.question.fetch("choices").map { |choice| choice.fetch("id") }).to match_array(allowed)
      round.answer!(at: 0, choice_id: round.question.fetch("target_id"))
      expect(PlayProgress.new(ace: ace, players: group.players).correct_player_ids).to match_array([ jalen.id, josh.id ])
      expect(setup(mode).available_count).to eq(0)
    end
  end

  it "does not widen empty filters or ignore a further player selection" do
    answer(jalen)
    answer(josh)
    expect(setup("name_ciphers").available_count).to eq(0)
    expect { setup("name_ciphers").start!(ace) }.to raise_error(ActiveModel::ValidationError)
    expect(setup("name_ciphers", filter: "missed").available_count).to eq(0)
    answer(josh, correct: false)
    expect(setup("name_ciphers", filter: "missed").available_count).to eq(1)
    expect(setup("name_ciphers", filter: "missed", player_ids: [ jalen.id ]).available_count).to eq(0)
  end

  it "suggests historical remaining players even when a learned member has a current team" do
    season = create(:season, league: league)
    [ jalen, josh ].each do |player|
      Activation.create!(player: player, campaign: Campaign.create!(team: player.team, season: season))
    end
    answer(jalen)
    josh.update!(team: nil)

    suggestion = setup("player_team_match").season_suggestion

    expect(suggestion.season_id).to eq(season.id)
    expect(suggestion.available_count).to eq(1)
    expect(suggestion.start!(ace).question.fetch("subject_id")).to eq(josh.id)
  end

  it "keeps only eligible due reviews and preserves their original choices" do
    round = setup("name_ciphers", filter: "all").start!(ace)
    round.questions.each_with_index do |question, position|
      choice = question.fetch("subject_id") == jalen.id ? jalen.id : nil
      round.answer!(at: position, choice_id: choice)
      round.advance!(at: position)
    end
    ace.practice_reviews.update_all(due_at: 1.minute.ago)

    review = setup("phased_repetition", filter: "missed").start!(ace)

    expect(review.length).to eq(1)
    expect(review.question.fetch("subject_id")).to eq(josh.id)
    expect(review.question.fetch("choices").map { |choice| choice.fetch("id") }).to match_array([ jalen.id, josh.id ])
  end

  it "intersects same-team player filters before choosing division questions" do
    conference = create(:conference, league: league)
    divisions = create_list(:division, 2, conference: conference)
    team.update!(division: divisions.first)
    rival.update!(division: divisions.last)
    josh.update!(team: team)
    answer(josh)

    expect(setup("guess_the_division", player_ids: [ josh.id ]).available_count).to eq(0)
    expect(setup("guess_the_division", player_ids: [ outsider.id ]).available_count).to eq(0)
    expect(setup("guess_the_division", player_ids: [ jalen.id ]).subjects.pluck(:id)).to eq([ team.id ])
  end

  it "rejects personalized filters without sign-in, a group, or a valid filter" do
    [
      { game_type: "name_ciphers", practice_filter: "remaining", player_group_id: group.id },
      { game_type: "name_ciphers", practice_filter: "remaining", ace: ace },
      { game_type: "name_ciphers", practice_filter: "unknown", player_group_id: group.id, ace: ace }
    ].each do |attributes|
      selected = GameRoundSetup.new(attributes)
      expect(selected.available_count).to eq(0)
      expect(selected).not_to be_valid
    end
  end

  it "uses only the signed-in account's progress and recalculates it for a new round" do
    answer(jalen)
    other = create(:ace)
    selected = setup("name_ciphers", ace: other)
    expect(selected.available_count).to eq(2)
    original = selected.start!(other)
    answer(josh)
    expect(original.reload.length).to eq(2)
    expect(setup("name_ciphers").available_count).to eq(0)
  end

  it "uses post-adoption quest coverage rather than pre-crediting lifetime answers" do
    answer(jalen)
    answer(josh)
    quest = create(:quest)
    create(:highlight, quest: quest, achievement: create(:achievement, target: group))
    entry = create(:goal, ace: ace, quest: quest).goal_achievements.sole
    round = setup("name_ciphers", goal_achievement_id: entry.id).start!(ace)
    expect(round.length).to eq(2)
    round.answer!(at: 0, choice_id: round.question.fetch("target_id"))
    expect(entry.reload.player_ids).to eq([ round.question.fetch("subject_id") ])
    expect(setup("name_ciphers", goal_achievement_id: entry.id).available_count).to eq(1)
  end

  it "keeps saved quest members available after a group membership edit" do
    quest = create(:quest)
    create(:highlight, quest: quest, achievement: create(:achievement, target: group))
    entry = create(:goal, ace: ace, quest: quest).goal_achievements.sole
    answer(jalen)
    entry.update!(player_ids: [ jalen.id ])
    group.players.delete(josh)
    group.players << outsider
    round = setup("name_ciphers", goal_achievement_id: entry.id).start!(ace)
    expect(round.question.fetch("subject_id")).to eq(josh.id)
    expect(round.question.fetch("choices").map { |choice| choice.fetch("id") }).to match_array([ jalen.id, josh.id ])
  end
end
