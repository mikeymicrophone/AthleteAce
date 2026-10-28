require "rails_helper"

RSpec.describe "Game history", type: :request do
  let(:ace) { create(:ace) }
  let(:player) { create(:player) }
  before { sign_in ace }

  it "shows recent answers across games without exposing other aces' history" do
    other_team = create(:team)
    wrong = create(:game_attempt, ace: ace, subject_entity: player, chosen_entity: other_team, is_correct: false)
    division = create(:division)
    right = create(:game_attempt, ace: ace, game_type: "guess_the_division", subject_entity: other_team, target_entity: division, chosen_entity: division)
    hidden = create(:game_attempt)
    get strength_game_attempts_path

    expect(response).to have_http_status(:ok)
    document = Nokogiri::HTML(response.body)
    expect(document.css(".history-attempt").map { |row| row["id"] }).to eq(["history_game_attempt_#{right.id}", "history_game_attempt_#{wrong.id}"])
    expect(document.css(".history-attempt").text).to include("Incorrect", "You chose", other_team.name, "Guess the Division", "Correct", division.name)
    expect(response.body).not_to include(hidden.subject_entity.name)
  end

  it "keeps game filters across tabs, team links and the legacy index" do
    team = player.team
    division = create(:division)
    create(:game_attempt, ace: ace, subject_entity: player)
    create(:game_attempt, ace: ace, game_type: "guess_the_division", subject_entity: team, target_entity: division, chosen_entity: division)
    get strength_game_attempts_path, params: { game_type: "guess_the_division", view: "teams" }
    document = Nokogiri::HTML(response.body)
    expect(document.css(".history-attempt").size).to eq(1)
    expect(document.at_css(".history-team-link")["href"]).to eq(team_strength_game_attempts_path(team, game_type: "guess_the_division"))
    expect(document.at_css(".history-tabs [aria-current=page]").text).to eq("By team")
    get game_attempts_path, params: { game_type: "guess_the_division" }
    expect(response).to redirect_to(strength_game_attempts_path(game_type: "guess_the_division"))
  end

  it "paginates attempts and keeps deleted entities readable" do
    create_list(:game_attempt, 21, ace: ace, subject_entity: player)
    player.destroy!
    get strength_game_attempts_path
    expect(response).to have_http_status(:ok)
    document = Nokogiri::HTML(response.body)
    expect(document.css(".history-attempt").size).to eq(20)
    expect(document.css(".history-attempt").text).to include("Subject no longer available")
    get strength_game_attempts_path, params: { page: 2 }
    expect(Nokogiri::HTML(response.body).css(".history-attempt").size).to eq(1)
  end

  it "restricts a mix-up drill to its two teams, including the answer choices" do
    other_team = create(:team, league: player.team.league)
    create(:player, team: other_team)
    quest_team = create(:team, league: player.team.league)
    create_list(:player, 3, team: quest_team)
    quest = create(:quest)
    quest.add_achievement create(:achievement, target: quest_team)
    ace.adopt_quest quest
    requested_ids = [player.team_id, other_team.id]
    get strength_team_match_path, params: { team_ids: requested_ids }
    expect(response).to have_http_status(:ok)
    document = Nokogiri::HTML(response.body)
    actual_ids = document.css("[data-game-target=answerChoice]").map { |choice| choice["data-guessable-id"].to_i }
    expect(actual_ids).to match_array(requested_ids)
    subject_id = document.at_css("[data-game-target=questionCard]")["data-player-id"]
    expect(Player.find(subject_id).team_id).to be_in(requested_ids)
  end

  it "does not substitute unrelated players when a drill has no available players" do
    teams = create_list(:team, 2)
    create(:player)
    get strength_team_match_path, params: { team_ids: teams.map(&:id) }
    expect(response).to redirect_to(strength_game_attempts_path)
    expect(flash[:alert]).to eq("No players are available for those teams.")
  end
end
