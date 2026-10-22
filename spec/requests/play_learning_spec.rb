require "rails_helper"

RSpec.describe "Play learning flows", type: :request do
  let(:ace) { create(:ace) }
  let(:team) { create(:team) }
  let!(:rival) { create(:team, league: team.league) }
  let!(:player) { create(:player, team: team) }
  let!(:other_player) { create(:player, team: rival) }

  it "offers six saved games and exposes only the signed-in ace's review count" do
    sign_in ace
    get new_game_round_path
    expect(response).to have_http_status(:ok)
    expect(Nokogiri::HTML(response.body).css('input[type="radio"][name="game_type"]').map { |i| i["value"] }).to match_array(GameRound::GAMES.keys)
    get strength_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Due for review", "0 questions")
  end

  it "scores new games on the server, records history, and refuses the legacy attempt API for saved-only modes" do
    sign_in ace
    round = GameRoundSetup.new(game_type: "multiple_choice").start!(ace)
    get game_round_path(round)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Which team is this player on?")
    post answer_game_round_path(round), params: { position: 0, choice_id: -1, is_correct: true }
    expect(round.game_attempts.count).to eq(0)
    post answer_game_round_path(round), params: { position: 0, choice_id: round.question["target_id"] }
    get strength_game_attempts_path, params: { game_type: "multiple_choice" }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Multiple Choice", "View round")
    post game_attempts_path, params: { game_attempt: { game_type: "image_recognition", subject_entity_type: "Player", subject_entity_id: player.id } }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "starts Quick round with due reviews before general practice" do
    sign_in ace
    round = GameRoundSetup.new.start!(ace)
    round.answer!(at: 0, choice_id: nil)
    ace.practice_reviews.update_all(due_at: 1.minute.ago)
    post play_quick_path
    expect(response).to redirect_to(game_round_path(GameRound.last))
    expect(GameRound.last.game_type).to eq("phased_repetition")
  end

  it "shows a photo question without putting the subject's name or initials in the heading" do
    sign_in ace
    [ player, other_player ].each { |p| p.update!(photo_urls: [ "https://example.com/photo.jpg" ]) }
    round = GameRoundSetup.new(game_type: "image_recognition").start!(ace)
    get game_round_path(round)
    expect(response).to have_http_status(:ok)
    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css(".round-subject h1").text).to eq("Who is this player?")
    expect(doc.at_css(".round-recognition-photo")["alt"]).to eq("Player to identify")
    expect(doc.css(".round-subject .round-jersey")).to be_empty
  end

  it "offers a stable anonymous preview, validates answers and never writes attempts or rounds" do
    get play_preview_path
    expect(response).to have_http_status(:ok)
    doc = Nokogiri::HTML(response.body)
    token = doc.at_css('input[name="token"]')["value"]
    choices = doc.css('button[name="choice_id"]').map { |b| b["value"] }
    expect(choices).to include(team.id.to_s, rival.id.to_s)
    expect(response.body).not_to include("Sign in to start saved rounds and track your streak")
    post play_preview_path, params: { token: token, choice_id: -1 }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Choose one of the answers shown")
    expect {
      post play_preview_path, params: { token: token, choice_id: choices.first, is_correct: true }
      follow_redirect!
    }.not_to change(GameAttempt, :count)
    expect(GameRound.count).to eq(0)
    expect(response.body).to include("Sign in to start saved rounds and track your streak")
    expect(Nokogiri::HTML(response.body).css('button[name="choice_id"]')).to be_empty
  end

  it "does not substitute other teams for an empty explicit preview scope" do
    empty = create(:team, league: team.league)
    get play_preview_path, params: { team_id: empty.id }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("No preview question available")
  end

  it "saves a selected time zone through the profile and rejects invalid values" do
    sign_in ace
    patch profile_path, params: { ace: { time_zone: "Hawaii" } }
    expect(response).to have_http_status(:see_other)
    expect(ace.reload.time_zone).to eq("Hawaii")
    patch profile_path, params: { ace: { time_zone: "Invented" } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(ace.reload.time_zone).to eq("Hawaii")
  end

  it "links team subjects in a Phased Repetition summary to their team pages" do
    conference = create(:conference, league: team.league)
    divisions = create_list(:division, 2, conference: conference)
    create(:membership, team: team, division: divisions.first)
    create(:membership, team: rival, division: divisions.last)
    original = GameRoundSetup.new(game_type: "guess_the_division", team_id: team.id).start!(ace)
    original.answer!(at: 0, choice_id: nil)
    ace.practice_reviews.update_all(due_at: 1.minute.ago)
    review = GameRoundSetup.new(game_type: "phased_repetition").start!(ace)
    review.answer!(at: 0, choice_id: review.question.fetch("target_id"))
    review.advance!(at: 0)
    sign_in ace
    get summary_game_round_path(review)
    expect(response).to have_http_status(:ok)
    link = Nokogiri::HTML(response.body).at_css(".round-result-subject")
    expect(link["href"]).to eq(team_path(team))
  end
end
