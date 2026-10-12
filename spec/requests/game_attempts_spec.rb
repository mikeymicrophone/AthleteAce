require 'rails_helper'

RSpec.describe "GameAttempts", type: :request do
  let(:ace) { create(:ace) }
  let(:player) { create(:player) }
  let(:other_team) { create(:team, league: player.team.league) }

  before { sign_in ace }

  def post_attempt(attributes)
    post game_attempts_path, params: { game_attempt: { game_type: "player_team_match", time_elapsed_ms: 1200 }.merge(attributes) }, as: :json
  end

  describe "POST /game_attempts" do
    it "scores a correct answer and records the real answer" do
      post_attempt subject_entity_type: "Player", subject_entity_id: player.id,
                   chosen_entity_type: "Team", chosen_entity_id: player.team_id

      expect(response).to have_http_status(:created)
      attempt = GameAttempt.last
      expect(attempt.target_entity).to eq(player.team)
      expect(attempt).to be_correct
    end

    it "ignores the client's claimed answer and correctness" do
      post_attempt subject_entity_type: "Player", subject_entity_id: player.id,
                   chosen_entity_type: "Team", chosen_entity_id: other_team.id,
                   target_entity_type: "Team", target_entity_id: other_team.id, is_correct: true

      expect(response).to have_http_status(:created)
      attempt = GameAttempt.last
      expect(attempt.target_entity).to eq(player.team)
      expect(attempt).not_to be_correct
    end

    it "scores the division game against the team's current division" do
      membership = create(:membership, team: other_team, active: true)

      post_attempt game_type: "guess_the_division",
                   subject_entity_type: "Team", subject_entity_id: other_team.id,
                   chosen_entity_type: "Division", chosen_entity_id: membership.division_id

      expect(response).to have_http_status(:created)
      expect(GameAttempt.last.target_entity).to eq(membership.division)
      expect(GameAttempt.last).to be_correct
    end

    it "rejects entity types that don't belong to the game" do
      expect {
        post_attempt subject_entity_type: "Ace", subject_entity_id: ace.id,
                     chosen_entity_type: "Team", chosen_entity_id: player.team_id
      }.not_to change(GameAttempt, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects unknown game types" do
      expect {
        post_attempt game_type: "made_up", subject_entity_type: "Player", subject_entity_id: player.id
      }.not_to change(GameAttempt, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
