require "rails_helper"

RSpec.describe "History mix-up drills", type: :request do
  let(:ace) { create(:ace) }
  let!(:players) { create_list(:player, 2) }

  before { sign_in ace }

  it "shows player pairs and preserves their scope across setup, starting and replay" do
    round = GameRoundSetup.new(game_type: "name_ciphers", player_ids: players.map(&:id)).start!(ace)
    wrong = round.question.fetch("choices").find { |choice| choice.fetch("id") != round.question.fetch("target_id") }
    round.answer!(at: 0, choice_id: wrong.fetch("id"))
    get strength_game_attempts_path, params: { game_type: "name_ciphers" }
    expect(response).to have_http_status(:ok)
    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css("#history-player-mixups-title").text).to eq("Players you mix up")
    href = doc.at_css('a[aria-label^="Drill names:"]')["href"]
    get href
    expect(response).to have_http_status(:ok)
    doc = Nokogiri::HTML(response.body)
    expect(doc.css('form.round-setup-form input[name="player_ids[]"]').map { |field| field["value"].to_i }).to match_array(players.map(&:id))
    post game_rounds_path, params: { game_type: "name_ciphers", player_ids: players.map(&:id), include_inactive: true }
    saved = ace.game_rounds.last
    expect(response).to redirect_to(game_round_path(saved))
    expect(saved.questions.map { |question| question.fetch("subject_id") }).to match_array(players.map(&:id))
    expect(saved.scope.fetch("player_ids")).to eq(players.map(&:id).map(&:to_s))
  end

  it "exposes team mix-ups when filtering Multiple Choice and hides irrelevant player cards" do
    round = GameRoundSetup.new(game_type: "multiple_choice", player_ids: players.map(&:id)).start!(ace)
    wrong = round.question.fetch("choices").find { |choice| choice.fetch("id") != round.question.fetch("target_id") }
    round.answer!(at: 0, choice_id: wrong.fetch("id"))
    get strength_game_attempts_path, params: { game_type: "multiple_choice" }
    expect(response.body).to include("Teams you mix up", "1 mix-up")
    expect(response.body).not_to include("Players you mix up")
    get strength_game_attempts_path, params: { game_type: "guess_the_division" }
    expect(response.body).not_to include("Teams you mix up", "Players you mix up")
  end
end
