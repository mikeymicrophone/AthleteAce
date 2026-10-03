require "rails_helper"

RSpec.describe "Game rounds", type: :request do
  let(:ace) { create(:ace) }
  let(:team) { create(:team) }
  let!(:rival) { create(:team, league: team.league) }
  let!(:player) { create(:player, team: team) }
  let(:round) { GameRoundSetup.new(team_id: team.id).start! ace }

  it "lets visitors set up, requires sign-in to start, and retains their selected scope" do
    get new_game_round_path, params: { team_id: team.id, length: 20 }, headers: { "Turbo-Frame" => "round_setup" }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Sign in to start", team.name)
    post game_rounds_path, params: { team_id: team.id }
    expect(response).to redirect_to(new_ace_session_path)
    post ace_session_path, params: { ace: { email: ace.email, password: "password123" } }
    expect(response.location).to include("/play/rounds/new", "team_id=#{team.id}", "length=20")
  end

  it "does not disclose or modify another ace's rounds" do
    owned_round = round
    intruder = create(:ace)
    [[:get, game_round_path(owned_round)], [:get, summary_game_round_path(owned_round)],
      [:post, answer_game_round_path(owned_round)], [:post, pause_game_round_path(owned_round)],
      [:post, resume_game_round_path(owned_round)], [:post, advance_game_round_path(owned_round)],
      [:post, drill_game_round_path(owned_round)]].each do |method, path|
      sign_in intruder
      public_send method, path
      expect(response).to have_http_status(:not_found)
    end
    expect(owned_round.reload.game_attempts).to be_empty
  end

  it "renders errors for an empty scope and never accepts a forged question list" do
    sign_in ace
    post game_rounds_path, params: { team_id: rival.id, questions: [{ target_id: team.id }] }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("No playable questions")
    expect(GameRound.count).to eq(0)
    post game_rounds_path, params: { team_id: team.id, length: 10, questions: [], ace_id: create(:ace).id }
    expect(response).to have_http_status(:see_other)
    expect(GameRound.last.ace).to eq(ace)
    expect(GameRound.last.questions.size).to eq(10)
  end

  it "serves answer feedback inside the game frame and rejects answers outside the shown choices" do
    sign_in ace
    get game_round_path(round)
    doc = Nokogiri::HTML(response.body)
    expect(doc.css(".round-choice[data-correct]")).to be_empty
    expect(doc.css(".round-choice").size).to eq(2)
    post answer_game_round_path(round), params: { position: 0, choice_id: -1, is_correct: true }
    follow_redirect!
    expect(response.body).to include("Choose one of the answers shown")
    expect(round.game_attempts).to be_empty
    post answer_game_round_path(round), params: { position: 0, choice_id: rival.id, target_entity_id: rival.id, is_correct: true }
    follow_redirect!
    expect(response.body).to include("Not quite", "round-choice-wrong", "round-choice-correct")
    expect(round.current_attempt).not_to be_correct
  end

  it "shows ordered completed results, links recorded attempts to the round, and starts a misses drill" do
    sign_in ace
    get summary_game_round_path(round)
    expect(response).to redirect_to(game_round_path(round))
    10.times do |position|
      round.answer! at: position, choice_id: position.zero? ? nil : team.id
      round.advance! at: position
    end
    get summary_game_round_path(round)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Round complete", "9 / 10", "Drill misses")
    expect(Nokogiri::HTML(response.body).css(".round-result-number").map(&:text)).to eq((1..10).map(&:to_s))
    get strength_game_attempts_path
    expect(response.body).to include(game_round_path(round), "View round")
    post drill_game_round_path(round)
    expect(GameRound.last.length).to eq(1)
    expect(response).to redirect_to(game_round_path(GameRound.last))
  end
end
