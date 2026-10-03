require "rails_helper"

RSpec.describe "Play home and quests", type: :request do
  let(:ace) { create(:ace) }
  let(:team) { create(:team) }
  let!(:rival) { create(:team, league: team.league) }
  let!(:player) { create(:player, team: team) }

  it "welcomes visitors without exposing another ace's activity" do
    round = GameRoundSetup.new(team_id: team.id).start! ace
    get strength_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Pick your first round", "sign in to play")
    expect(response.body).not_to include(game_round_path(round), "play-scoreboard")
    expect(Nokogiri::HTML(response.body).at_css(".nav-play")[:class]).to include("active")
  end

  it "shows only the current ace's rounds, activity and active quest progress" do
    own = GameRoundSetup.new(team_id: team.id).start! ace
    own.answer! at: 0, choice_id: team.id
    own.advance! at: 0
    own.pause!
    foreign = GameRoundSetup.new(team_id: team.id).start! create(:ace)
    foreign.answer! at: 0, choice_id: rival.id
    quest = create(:quest, name: "My roster challenge")
    create_list(:highlight, 2, quest: quest)
    create(:highlight, :optional, quest: quest)
    create(:goal, ace: ace, quest: quest, progress: 1, status: "in_progress")
    create(:goal, ace: ace, quest: create(:quest, name: "Finished challenge"), status: "completed")
    sign_in ace
    get strength_path
    expect(response.body).to include(game_round_path(own), "1 of 10 answered", "My roster challenge", "1 of 2 required achievements")
    expect(response.body).not_to include(game_round_path(foreign), "Finished challenge")
    stats = Nokogiri::HTML(response.body).css(".play-scoreboard strong").map(&:text)
    expect(stats).to eq(["100%", "1", "1 / 7"])
  end

  it "keeps existing scoped strength links pointed at round setup" do
    get strength_path, params: { team_id: team.id, length: 20 }
    expect(response).to redirect_to(new_game_round_path(team_id: team.id, length: 20))
  end

  it "shows required progress separately from optional achievements and scopes practice" do
    quest = create(:quest)
    achievement = create(:achievement, target: team, name: "Learn this roster")
    create(:highlight, quest: quest, achievement: achievement)
    create(:highlight, :optional, quest: quest)
    goal = create(:goal, ace: ace, quest: quest, progress: 5)
    sign_in ace
    get quest_path(quest)
    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css("progress")[:value]).to eq("100")
    expect(response.body).to include("1 of 1 required achievements", new_game_round_path(team_id: team.id), goal_path(goal))
    expect(response.body).not_to include("Approved", "Created by")
    expect(goal.reload.progress).to eq(5)
    sign_out ace
    get quest_path(quest)
    expect(response.body).to include("Sign in to begin")
    expect(Nokogiri::HTML(response.body).css("progress")).to be_empty
  end

  it "renders a useful empty quest list" do
    get quests_path
    expect(response.body).to include("No quests yet", new_game_round_path)
  end
end
