require "rails_helper"

RSpec.describe "Group learning pages", type: :request do
  let(:ace) { create(:ace) }
  let!(:players) { create_list(:player, 2) }
  let!(:group) { PlayerGroup.create!(name: "Names to learn", players: players) }

  it "shows personal coverage and remaining practice without exposing it to visitors" do
    create(:game_attempt, ace: ace, subject_entity: players.first, is_correct: true)
    sign_in ace
    get player_group_path(group)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("1 of 2", "Practice remaining 1", "Answered correctly", "Not practiced")
    sign_out ace
    get player_group_path(group)
    expect(response.body).not_to include("Your group practice", "Practice remaining", "1 of 2", "Answered correctly")
    expect(response.body).to include("to see your group practice progress")
  end

  it "preserves a remaining filter through setup and creates only eligible questions" do
    sign_in ace
    create(:game_attempt, ace: ace, subject_entity: players.first, is_correct: true)
    get new_game_round_path(player_group_id: group.id, practice_filter: "remaining", game_type: "name_ciphers")
    expect(response).to have_http_status(:ok)
    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css('select[name="practice_filter"] option[selected]')["value"]).to eq("remaining")
    post game_rounds_path, params: { player_group_id: group.id, practice_filter: "remaining", game_type: "name_ciphers" }
    round = ace.game_rounds.last
    expect(response).to redirect_to(game_round_path(round))
    expect(round.questions.map { |question| question.fetch("subject_id") }).to eq([ players.last.id ])
    expect(round.scope.fetch("practice_filter")).to eq("remaining")
  end

  it "prevents another account's answers from filling current coverage" do
    create(:game_attempt, ace: ace, subject_entity: players.first, is_correct: true)
    sign_in create(:ace)
    get player_group_path(group)
    expect(response.body).to include("0 of 2", "Practice remaining 2")
  end

  it "shows completed coverage and offers misses separately after a later wrong answer" do
    players.each { |player| create(:game_attempt, ace: ace, subject_entity: player, is_correct: true) }
    create(:game_attempt, ace: ace, subject_entity: players.last, is_correct: false)
    sign_in ace
    get player_group_path(group)
    expect(response.body).to include("Every current member has been answered correctly", "Practice misses", "Needs practice")
    expect(response.body).not_to include("Practice remaining")
  end
end
