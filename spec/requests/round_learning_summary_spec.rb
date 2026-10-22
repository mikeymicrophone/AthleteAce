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
end
