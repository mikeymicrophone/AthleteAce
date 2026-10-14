require "rails_helper"

RSpec.describe "Moderation boundaries", type: :request do
  let(:author) { create(:ace) }
  let(:other) { create(:ace) }
  let(:reviewer) { create(:ace, moderator: true) }

  it "assigns authorship server-side and hides pending content in HTML and JSON from other people" do
    sign_in author
    post quests_path, params: { quest: { name: "Private pending quest", created_by_id: other.id, moderation_status: "approved" } }
    quest = Quest.last
    expect(quest.created_by).to eq(author)
    expect(quest.moderation_status).to eq("pending")
    get quest_path(quest)
    expect(response.body).to include("Only you and reviewers")
    delete destroy_ace_session_path
    [ quest_path(quest), quest_path(quest, format: :json) ].each do |path|
      get path
      expect(response).to have_http_status(:not_found)
    end
    get quests_path
    expect(response.body).not_to include("Private pending quest")
    sign_in other
    post quest_goals_path(quest)
    expect(response).to have_http_status(:not_found)
  end

  it "filters pending spectra from pickers and rejects forged rating submissions" do
    spectrum = create(:spectrum, created_by: author, name: "Private spectrum")
    player = create(:player)
    sign_in other
    get player_path(player), params: { spectrum_ids: [ spectrum.id ] }
    expect(response.body).not_to include("Private spectrum")
    expect {
      post player_ratings_path(player), params: { rating: { spectrum_id: spectrum.id, value: 100 } }, as: :json
    }.not_to change(Rating, :count)
    expect(response).to have_http_status(:not_found)
  end

  it "protects the queue and log and allows a moderator to decide another ace's submission" do
    quest = create(:quest, created_by: author)
    sign_in other
    get moderation_path
    expect(response).to have_http_status(:forbidden)
    get moderation_log_path
    expect(response).to have_http_status(:forbidden)
    sign_in reviewer
    get moderation_path
    expect(response.body).to include(quest.name)
    patch moderation_item_path(type: "Quest", id: quest.id), params: { decision: "approve", revision: 1, status: "pending" }
    expect(quest.reload).to be_approved
    patch moderation_item_path(type: "Quest", id: quest.id), params: { decision: "reject", revision: 1, status: "pending", reason: "Late decision" }
    expect(response).to have_http_status(:conflict)
    expect(quest.moderation_decisions.count).to eq(2)
  end

  it "keeps an author's pending spectrum out of public player rating summaries" do
    spectrum = create(:spectrum, created_by: author, name: "Author-only spectrum")
    public_spectrum = create(:spectrum, name: "Public spectrum")
    player = create(:player)
    create(:rating, ace: author, target: player, spectrum: public_spectrum, value: 100)
    sign_in author
    post player_ratings_path(player), params: { rating: { spectrum_id: spectrum.id, value: 200 } }, as: :json
    expect(response).to have_http_status(:created)
    delete destroy_ace_session_path
    get players_path
    expect(response.body).to include("Public spectrum")
    expect(response.body).not_to include("Author-only spectrum")
    sign_in other
    get players_path
    expect(response.body).not_to include("Author-only spectrum")
    sign_in author
    get players_path
    expect(response.body).to include("Author-only spectrum")
  end

  it "does not expose pending parent achievements through approved quest links or forged highlights" do
    quest = create(:quest)
    achievement = create(:achievement, created_by: author, name: "Hidden achievement")
    create(:highlight, quest: quest, achievement: achievement)
    sign_in other
    get quest_path(quest)
    expect(response.body).not_to include("Hidden achievement")
    expect {
      post quest_highlights_path(quest), params: { highlight: { achievement_id: achievement.id } }
    }.not_to change(Highlight, :count)
    expect(response).to have_http_status(:unprocessable_content)
  end
end
