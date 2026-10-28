require "rails_helper"

RSpec.describe "Name Cipher rounds", type: :request do
  let(:ace) { create(:ace) }
  let(:team) { create(:team) }
  let!(:players) { create_list(:player, 5, team: team, active: true) }

  it "scores against the saved player choices and rejects unsaved or forged answers" do
    sign_in ace
    post game_rounds_path, params: { game_type: "name_ciphers", team_ids: [ team.id ], length: 10 }
    round = ace.game_rounds.last
    question = round.question
    expect(question.fetch("choices").size).to eq(4)
    post answer_game_round_path(round), params: { position: 0, choice_id: -1, is_correct: true }
    expect(round.game_attempts).to be_empty
    wrong = question.fetch("choices").find { |choice| choice.fetch("id") != question.fetch("target_id") }
    post answer_game_round_path(round), params: { position: 0, choice_id: wrong.fetch("id"), target_entity_id: wrong.fetch("id"), is_correct: true }
    expect(round.current_attempt).to have_attributes(is_correct: false, subject_entity_type: "Player", target_entity_type: "Player", chosen_entity_id: wrong.fetch("id"))
    post answer_game_round_path(round), params: { position: 0, choice_id: question.fetch("target_id") }
    expect(round.game_attempts.count).to eq(1)
    post game_attempts_path, params: { game_attempt: { game_type: "name_ciphers", subject_entity_type: "Player",
      subject_entity_id: players.first.id, chosen_entity_type: "Player", chosen_entity_id: players.first.id, time_elapsed_ms: 100 } }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(GameAttempt.count).to eq(1)
  end
end
