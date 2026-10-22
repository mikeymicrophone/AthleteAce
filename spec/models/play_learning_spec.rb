require "rails_helper"

RSpec.describe "Play learning" do
  include ActiveSupport::Testing::TimeHelpers

  let(:ace) { create(:ace) }
  let(:league) { create(:league) }
  let!(:team) { create(:team, league: league) }
  let!(:rival) { create(:team, league: league) }
  let!(:jalen) { create(:player, first_name: "Jalen", last_name: "Brunson", team: team) }
  let!(:josh) { create(:player, first_name: "Josh", last_name: "Hart", team: rival) }

  def start(mode, **scope)
    GameRoundSetup.new({ game_type: mode, league_id: league.id }.merge(scope)).start!(ace)
  end

  it "saves scoped player facts with up to four different choices and preserves them after catalog edits" do
    create(:player)
    round = start("multiple_choice")
    expect(round.length).to eq(2)
    expect(round.questions.map { |q| q["subject_id"] }).to match_array([ jalen.id, josh.id ])
    question = round.question
    expect(question["choices"].map { |c| c["id"] }).to match_array([ team.id, rival.id ])
    team.update!(mascot: "New name")
    expect(round.reload.question).to eq(question)
    round.answer!(at: 0, choice_id: question["target_id"])
    round.pause!
    round.resume!
    expect(round.reload.current_attempt).to be_correct
    expect(round.game_attempts.count).to eq(1)
  end

  it "uses recorded birth facts and never substitutes unrelated players for an empty scope" do
    countries = create_list(:country, 2)
    jalen.update!(birth_country: countries.first)
    josh.update!(birth_country: countries.last)
    round = start("multiple_choice", fact_type: "birth_country")
    expect(round.question["target_type"]).to eq("Country")
    empty = create(:team, league: league)
    expect { start("multiple_choice", team_id: empty.id) }.to raise_error(ActiveModel::ValidationError, /No playable/)
    expect { start("multiple_choice", fact_type: "invented") }.to raise_error(ActiveModel::ValidationError)
    expect(GameRoundSetup.new(game_type: "multiple_choice", team_id: team.id).available_count).to eq(0)
  end

  it "includes only photographed players and excludes ambiguous duplicate display names for image recognition" do
    expect(GameRoundSetup.new(game_type: "image_recognition").available_count).to eq(0)
    jalen.update!(photo_urls: [ "https://example.com/jalen.jpg" ])
    josh.update!(photo_urls: [ "https://example.com/josh.jpg" ])
    create(:player, first_name: "Jalen", last_name: "Brunson", team: team, photo_urls: [ "https://example.com/another.jpg" ])
    round = start("image_recognition")
    expect(round.length).to eq(2)
    expect(round.question["subject_photo_url"]).to be_present
    expect(round.question["target_id"]).to eq(round.question["subject_id"])
  end

  it "schedules misses, resumes due original questions, spaces successes and does not record retries twice" do
    travel_to Time.zone.local(2026, 10, 21, 12) do
      round = start("multiple_choice")
      question = round.question
      round.answer!(at: 0, choice_id: nil)
      review = ace.practice_reviews.sole
      expect(review.due_at).to eq(10.minutes.from_now)
      expect(ReviewQueue.new(ace: ace).entries).to be_empty
      expect(ReviewQueue.new(ace: create(:ace)).entries).to be_empty
      round.answer!(at: 0, choice_id: question["target_id"])
      expect(ace.practice_reviews.count).to eq(1)
      expect(review.reload.correct_streak).to eq(0)
      travel 11.minutes
      due = start("phased_repetition")
      expect(due.length).to eq(1)
      expect(due.question).to include("game_type" => "multiple_choice", "target_id" => question["target_id"])
      due.answer!(at: 0, choice_id: due.question["target_id"])
      expect(review.reload.correct_streak).to eq(1)
      expect(review.due_at).to eq(1.day.from_now)
      travel 1.day
      next_review = start("phased_repetition")
      next_review.answer!(at: 0, choice_id: next_review.question["target_id"])
      expect(review.reload.due_at).to eq(3.days.from_now)
      expect(ace.practice_reviews.count).to eq(1)
    end
  end

  it "keeps reviews in the selected scope and drops questions with deleted answer choices" do
    round = start("multiple_choice")
    round.answer!(at: 0, choice_id: nil)
    ace.practice_reviews.update_all(due_at: 1.minute.ago)
    other = create(:team)
    expect(GameRoundSetup.new(game_type: "phased_repetition", team_id: other.id, ace: ace).available_count).to eq(0)
    expect(ReviewQueue.new(ace: ace).entries.size).to eq(1)
    Player.where(id: round.question["subject_id"]).delete_all
    expect(ReviewQueue.new(ace: ace).entries).to be_empty
  end

  it "uses all player games for knowledge and miss drills and records names newly learned by a round" do
    round = start("multiple_choice")
    question = round.question
    create(:game_attempt, ace: ace, subject_entity: Player.find(question["subject_id"]))
    round.answer!(at: 0, choice_id: question["target_id"])
    expect(round.reload.newly_known_player_ids).to eq([ question["subject_id"] ])
    expect(PlayProgress.new(ace: ace).names_known).to eq(1)
    failed = start("multiple_choice", player_id: nil)
    failed.answer!(at: 0, choice_id: nil)
    misses = PlayProgress.new(ace: ace).misses
    expect(misses.map { |m| m[:player].id }).to include(failed.question["subject_id"])
    drill = GameRoundSetup.new.start_misses!(ace)
    expect(drill.game_type).to eq("phased_repetition")
    expect(drill.question["game_type"]).to eq("multiple_choice")
  end

  it "completes a quest after every saved roster player is correct once without counting repeats or later additions" do
    josh.update!(team: team)
    quest = create(:quest)
    achievement = create(:achievement, target: team)
    quest.add_achievement(achievement)
    goal = ace.adopt_quest(quest)
    entry = goal.goal_achievements.sole
    expect(entry.required_player_ids).to match_array([ jalen.id, josh.id ])
    expect(goal.next_achievement).to eq(achievement)
    create(:player, team: team)
    round = GameRoundSetup.new(team_id: team.id, player_id: jalen.id).start!(ace)
    round.answer!(at: 0, choice_id: nil)
    expect(entry.reload.progress).to eq(0)
    2.times do
      game = GameRoundSetup.new(team_id: team.id, player_id: jalen.id).start!(ace)
      game.answer!(at: 0, choice_id: team.id)
    end
    expect(entry.reload.progress).to eq(1)
    expect(goal.reload.status).to eq("in_progress")
    game = GameRoundSetup.new(team_id: team.id, player_id: josh.id).start!(ace)
    game.answer!(at: 0, choice_id: team.id)
    expect(entry.reload.progress).to eq(2)
    expect(entry.completed_at).to be_present
    expect(goal.reload.status).to eq("completed")
    expect(goal.percent_complete).to eq(100)
    expect(goal.next_achievement).to be_nil
  end

  it "does not count another ace's answers or answers before quest adoption" do
    game = GameRoundSetup.new(team_id: team.id).start!(ace)
    game.answer!(at: 0, choice_id: team.id)
    quest = create(:quest)
    quest.add_achievement(create(:achievement, target: team))
    goal = ace.adopt_quest(quest)
    other = create(:ace)
    other_game = GameRoundSetup.new(team_id: team.id).start!(other)
    other_game.answer!(at: 0, choice_id: team.id)
    expect(goal.goal_achievements.sole.progress).to eq(0)
    expect(goal.reload.progress).to eq(0)
  end

  it "uses each ace's selected time zone for streaks and history at midnight" do
    ace.update!(time_zone: "Hawaii")
    travel_to Time.utc(2026, 10, 21, 2) do
      create(:game_attempt, ace: ace, subject_entity: jalen, created_at: Time.current)
      progress = PlayProgress.new(ace: ace)
      expect(progress.streaks[:current]).to eq(1)
      expect(GameHistory.new(ace: ace).today).to eq(Date.new(2026, 10, 20))
      expect(progress.players_today).to include(jalen)
    end
  end

  it "includes inactive assigned players in quest coverage and keeps that practice scope" do
    josh.update!(team: team, active: false)
    quest = create(:quest)
    quest.add_achievement(create(:achievement, target: team))
    goal = ace.adopt_quest(quest)
    entry = goal.goal_achievements.sole
    expect(entry.required_player_ids).to match_array([ jalen.id, josh.id ])
    expect(entry.practice_scope.fetch("include_inactive")).to be(true)
    expect(GameRoundSetup.new(entry.practice_scope).subjects).to include(josh)
  end

  it "keeps historical team filters and history attached to the saved question after a transfer" do
    round = GameRoundSetup.new(team_id: team.id).start!(ace)
    round.answer!(at: 0, choice_id: nil)
    jalen.update!(team: create(:team))
    ace.practice_reviews.update_all(due_at: 1.minute.ago)
    review = GameRoundSetup.new(game_type: "phased_repetition", team_id: team.id).start!(ace)
    expect(review.question.fetch("team_id")).to eq(team.id)
    review.answer!(at: 0, choice_id: team.id)
    expect(GameHistory.new(ace: ace, game_type: "phased_repetition", team: team).attempts.count).to eq(1)
  end

  it "includes the first history day from midnight in a zone ahead of the application zone" do
    ace.update!(time_zone: "Tokyo")
    travel_to Time.utc(2026, 10, 21, 12) do
      create(:game_attempt, ace: ace, subject_entity: jalen, created_at: Time.utc(2026, 10, 7, 15, 5))
      expect(GameHistory.new(ace: ace).days.first).to include(date: Date.new(2026, 10, 8), total: 1)
    end
  end

  it "builds seasonal facts and photo questions without inventing current-team assignments" do
    season = create(:season, league: league)
    campaign = Campaign.create!(team: team, season: season)
    other_campaign = Campaign.create!(team: rival, season: season)
    Activation.create!(player: jalen, campaign: campaign)
    Activation.create!(player: josh, campaign: other_campaign)
    [ jalen, josh ].each { |player| player.update!(team: nil, photo_urls: [ "/icon.png" ]) }
    facts = start("multiple_choice", season_id: season.id)
    expect(facts.questions.map { |q| q["target_id"] }).to match_array([ team.id, rival.id ])
    expect(facts.questions.all? { |q| q["season_name"] == season.name }).to be(true)
    images = start("image_recognition", season_id: season.id)
    expect(images.length).to eq(2)
    expect(images.questions.map { |q| q["team_id"] }).to match_array([ team.id, rival.id ])
    expect(GameRoundSetup.new(game_type: "multiple_choice", league_id: league.id).season_suggestion.season).to eq(season)
    expect(jalen.reload.team).to be_nil
  end
end
