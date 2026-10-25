require "rails_helper"

RSpec.describe "Round learning summaries", type: :request do
  let(:ace) { create(:ace) }
  let!(:players) { create_list(:player, 3) }
  let!(:group) { PlayerGroup.create!(name: "Names to learn", players: players.first(2)) }

  before { sign_in ace }

  def start_round(**attributes)
    GameRoundSetup.new({ game_type: "name_ciphers", player_group_id: group.id }.merge(attributes)).start!(ace)
  end

  def finish(round, correct: true)
    round.questions.each_with_index do |question, position|
      round.answer!(at: position, choice_id: correct ? question.fetch("target_id") : nil)
      round.advance!(at: position)
    end
  end

  def adopt(owner: ace)
    quest = create(:quest, name: "Courtside challenge")
    achievement = create(:achievement, target: group, name: "Learn the first names")
    create(:highlight, quest: quest, achievement: achievement, position: 0)
    goal = create(:goal, ace: owner, quest: quest)
    [ goal, goal.goal_achievements.sole ]
  end

  it "shows live group coverage without changing recorded round results" do
    round = start_round
    finish(round, correct: false)
    group.players << players.last
    create(:game_attempt, ace: ace, subject_entity: players.first, is_correct: true)
    get summary_game_round_path(round)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Current group progress", "1 of 3", "Practice remaining 2")
    expect(Nokogiri::HTML(response.body).at_css(".round-final-score").text).to eq("0 / 2")
    expect(round.reload.stats[:correct]).to eq(0)
  end

  it "offers full-group practice after finishing every member" do
    round = start_round
    finish(round)
    get summary_game_round_path(round)
    expect(response.body).to include("2 of 2", "Every current member answered correctly")
    expect(response.body).not_to include("Practice remaining")
    link = Nokogiri::HTML(response.body).at_css('a[aria-label^="Practice group:"]')
    expect(Rack::Utils.parse_nested_query(URI.parse(link["href"]).query)).not_to have_key("practice_filter")
  end

  it "continues the adopted achievement using post-adoption remaining players" do
    goal, entry = adopt
    round = start_round(goal_achievement_id: entry.id)
    round.answer!(at: 0, choice_id: round.question.fetch("target_id"))
    round.advance!(at: 0)
    round.answer!(at: 1, choice_id: nil)
    round.advance!(at: 1)
    get summary_game_round_path(round)
    expect(response.body).to include("Your quest progress", goal.quest.name, "1 of 2 players answered correctly since adoption")
    expect(response.body).not_to include("Current group progress")
    link = Nokogiri::HTML(response.body).css("a").find { |node| node.text == "Continue achievement: #{entry.achievement.name}" }
    query = Rack::Utils.parse_nested_query(URI.parse(link["href"]).query)
    expect(query).to include("goal_achievement_id" => entry.id.to_s, "practice_filter" => "remaining", "game_type" => "name_ciphers")
    get link["href"]
    expect(response.body).to include("1 player available")
  end

  it "continues the displayed unfinished achievement even when an earlier requirement remains" do
    goal, first_entry = adopt
    later_group = PlayerGroup.create!(name: "Later names", players: players.last(2))
    later_achievement = create(:achievement, target: later_group, name: "Learn the later names")
    create(:highlight, quest: goal.quest, achievement: later_achievement, position: 1)
    goal.prepare_learning!
    later_entry = goal.goal_achievements.find_by!(achievement: later_achievement)
    round = start_round(player_group_id: later_group.id, goal_achievement_id: later_entry.id)
    finish(round, correct: false)
    get summary_game_round_path(round)
    expect(response.body).to include("Continue achievement: #{later_achievement.name}")
    expect(response.body).not_to include("Next achievement: #{first_entry.achievement.name}")
    link = Nokogiri::HTML(response.body).css("a").find { |node| node.text == "Continue achievement: #{later_achievement.name}" }
    query = Rack::Utils.parse_nested_query(URI.parse(link["href"]).query)
    expect(query).to include("goal_achievement_id" => later_entry.id.to_s, "player_group_id" => later_group.id.to_s)
  end

  it "offers the next required achievement and retains its adopted roster" do
    goal, entry = adopt
    next_group = PlayerGroup.create!(name: "Next names", players: players.last(2))
    next_achievement = create(:achievement, target: next_group, name: "Learn the next names")
    create(:highlight, quest: goal.quest, achievement: next_achievement, position: 1)
    goal.prepare_learning!
    next_entry = goal.goal_achievements.find_by!(achievement: next_achievement)
    next_group.players.delete(players.last)
    round = start_round(goal_achievement_id: entry.id)
    finish(round)
    get summary_game_round_path(round)
    expect(response.body).to include("Achievement complete", "Next achievement: #{next_achievement.name}")
    expect(response.body).not_to include("Quest complete")
    link = Nokogiri::HTML(response.body).css("a").find { |node| node.text == "Next achievement: #{next_achievement.name}" }
    get link["href"]
    expect(response.body).to include("1 player available")
    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css('input[name="goal_achievement_id"]')["value"]).to eq(next_entry.id.to_s)
  end

  it "celebrates a completed quest without crediting later group additions" do
    goal, entry = adopt
    round = start_round(goal_achievement_id: entry.id)
    finish(round)
    group.players << players.last
    get summary_game_round_path(round)
    expect(response.body).to include("Quest complete", "2 of 2 players answered correctly since adoption", "Explore quests")
    expect(response.body).not_to include("2 of 3", "Current group progress")
    expect(goal.reload.status).to eq("completed")
  end

  it "never displays another account's quest from a mismatched saved reference" do
    goal, entry = adopt(owner: create(:ace))
    round = start_round
    round.update!(scope: round.scope.merge("goal_achievement_id" => entry.id))
    finish(round)
    get summary_game_round_path(round)
    expect(response.body).not_to include(goal.quest.name, entry.achievement.name, "Your quest progress")
    expect(response.body).to include("Current group progress")
  end

  it "hides quest progress if its achievement or requirement is no longer public" do
    goal, entry = adopt
    round = start_round(goal_achievement_id: entry.id)
    finish(round)
    entry.achievement.update!(moderation_status: "hidden")
    get summary_game_round_path(round)
    expect(response.body).not_to include(goal.quest.name, entry.achievement.name, "Quest complete")
    entry.achievement.update!(moderation_status: "approved")
    goal.quest.highlights.sole.update!(moderation_status: "hidden")
    get summary_game_round_path(round)
    expect(response.body).not_to include(goal.quest.name, entry.achievement.name, "Quest complete")
  end

  it "keeps deleted-group results readable without offering a broken replay" do
    round = start_round
    finish(round)
    group.destroy!
    get summary_game_round_path(round)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("This group is no longer available", "2 / 2", "Choose another game")
    expect(response.body).not_to include("Play again", "Current group progress")
  end

  def adopt_target(target, owner: ace, name: "Learn the roster")
    quest = create(:quest, name: name)
    achievement = create(:achievement, target: target, name: "Learn #{target.name}")
    create(:highlight, quest: quest, achievement: achievement)
    goal = create(:goal, ace: owner, quest: quest)
    [ goal, goal.goal_achievements.sole ]
  end

  it "shows current player, team, league and sport quest progress from the round's player subjects" do
    players.second.update! team: players.first.team
    targets = [ players.first, players.first.team, players.first.league, players.first.sport ]
    goals = targets.each_with_index.map { |target, i| adopt_target(target, name: "Roster challenge #{i}").first }
    round = start_round
    finish(round)
    get summary_game_round_path(round)
    expect(response).to have_http_status(:ok)
    doc = Nokogiri::HTML(response.body)
    expect(doc.css(".round-learning-progress").size).to eq(4)
    goals.each { |goal| expect(response.body).to include(goal.quest.name) }
    expect(response.body).to include("Current progress for your adopted roster")
    expect(doc.at_css(".round-final-score").text).to eq("2 / 2")
    ids = doc.css(".round-learning-progress h2").map { |node| node["id"] }
    expect(ids.uniq).to eq(ids)
  end

  it "retains the adopted team roster when new players are added and never rewrites saved results" do
    players.second.update! team: players.first.team
    goal, entry = adopt_target(players.first.team)
    late_player = create(:player, team: players.first.team)
    group.players << late_player
    round = start_round
    finish(round)
    before = round.attributes
    get summary_game_round_path(round)
    expect(response.body).to include("Quest complete", "2 of 2 players answered correctly since adoption")
    expect(entry.reload.required_player_ids).to match_array(players.first(2).map(&:id))
    expect(entry.player_ids).not_to include(late_player.id)
    expect(round.reload.attributes).to eq(before)
    expect(goal.reload.status).to eq("completed")
  end

  it "omits other accounts, unrelated subjects and quests adopted after the round" do
    other_goal, = adopt_target(players.first, owner: create(:ace), name: "Another account's quest")
    unrelated, = adopt_target(players.last, name: "Another player's quest")
    round = start_round
    finish(round)
    later, = adopt_target(players.first, name: "Adopted after finishing")
    get summary_game_round_path(round)
    expect(response.body).not_to include(other_goal.quest.name, unrelated.quest.name, later.quest.name, "Your quest progress")
    expect(response.body).to include("Current group progress")
  end

  it "hides generic quest progress when any public requirement becomes unavailable" do
    goal, entry = adopt_target(players.first)
    round = start_round
    finish(round)
    [ goal.quest, entry.achievement, goal.quest.highlights.sole ].each do |record|
      record.update! moderation_status: "hidden"
      get summary_game_round_path(round)
      expect(response.body).not_to include(goal.quest.name, "Quest complete")
      record.update! moderation_status: "approved"
    end
  end

  it "shows one progress panel for a quest with multiple matching achievements" do
    goal, = adopt_target(players.first.team)
    achievement = create(:achievement, target: players.first, name: "Learn this player")
    create(:highlight, quest: goal.quest, achievement: achievement)
    goal.prepare_learning!
    round = start_round
    finish(round, correct: false)
    get summary_game_round_path(round)
    expect(Nokogiri::HTML(response.body).css(".round-learning-progress").size).to eq(1)
    expect(response.body).to include(goal.quest.name, "Your quest progress")
  end

  it "records quest progress at round start and finish while keeping later progress separate" do
    goal, entry = adopt_target(players.first)
    later_achievement = create(:achievement, target: players.last, name: "Learn the next player")
    create(:highlight, quest: goal.quest, achievement: later_achievement)
    goal.prepare_learning!
    round = start_round
    expect(round.scope.fetch("quest_progress").sole.fetch("before")).to eq("completed" => 0, "required" => 2, "percent" => 0)
    finish(round)
    saved = round.reload.scope.fetch("quest_progress")
    expect(saved.sole.fetch("after")).to eq("completed" => 1, "required" => 2, "percent" => 50)
    later_round = GameRoundSetup.new(game_type: "name_ciphers", player_ids: [ players.first.id, players.last.id ]).start!(ace)
    finish(later_round)
    get summary_game_round_path(round)
    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css('[data-quest-progress-point="before"]').text).to include("0% · 0 of 2")
    expect(doc.at_css('[data-quest-progress-point="after"]').text).to include("50% · 1 of 2")
    expect(doc.at_css(".quest-progress strong").text).to eq("100%")
    round.advance!(at: round.length - 1)
    expect(round.reload.scope.fetch("quest_progress")).to eq(saved)
    replay = Nokogiri::HTML(response.body).css("a").find { |link| link.text == "Play again" }
    expect(replay["href"]).not_to include("quest_progress")
    expect(entry.reload.progress).to eq(1)
  end

  it "does not invent historical percentages for older rounds without snapshots" do
    goal, = adopt_target(players.first)
    round = start_round
    round.update! scope: round.scope.except("quest_progress")
    finish(round)
    get summary_game_round_path(round)
    expect(response.body).to include(goal.quest.name, "Quest complete")
    expect(response.body).not_to include("At round start", "At round finish")
  end

  it "shows live progress but no recorded pair for a quest adopted during the round" do
    round = start_round
    goal, = adopt_target(players.first)
    finish(round)
    get summary_game_round_path(round)
    expect(response.body).to include(goal.quest.name, "Quest complete")
    expect(response.body).not_to include("At round start", "At round finish")
    expect(round.reload.scope).not_to have_key("quest_progress")
  end
end
