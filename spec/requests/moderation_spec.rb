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

  it "counts and filters reviewable submissions without counting the reviewer's own content" do
    quest = create(:quest, created_by: author, name: "Waiting quest")
    spectrum = create(:spectrum, created_by: author, name: "Waiting spectrum")
    create(:quest, created_by: reviewer, name: "My own submission")
    catalog = create(:quest, name: "Trusted catalog quest")
    sign_in reviewer

    get moderation_path
    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css('[aria-label="Submission type"]').text).to include("All 2", "Quests 1", "Spectrums 1")
    expect(response.body).to include(quest.name, spectrum.name)
    expect(response.body).not_to include("My own submission", catalog.name)

    get moderation_path, params: { item_type: "Quest" }
    expect(response.body).to include(quest.name, "1 submission")
    expect(response.body).not_to include(spectrum.name)
    expect(Nokogiri::HTML(response.body).at_css('[aria-label="Submission status"] a[aria-current="page"]').text).to eq("Pending")

    get moderation_path, params: { status: "approved", item_type: "Quest" }
    expect(response.body).to include(catalog.name)
    expect(response.body).not_to include(quest.name)
    get moderation_path, params: { queue_status: "forged", item_type: "Ace" }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(quest.name, spectrum.name)
  end

  it "paginates a mixed queue in a stable order and navigates across page boundaries" do
    timestamp = 1.hour.ago
    quests = create_list(:quest, 25, created_by: author, created_at: timestamp)
    spectrum = create(:spectrum, created_by: author, name: "The next page", created_at: timestamp)
    sign_in reviewer
    get moderation_path
    rows = Nokogiri::HTML(response.body).css(".moderation-row")
    expect(rows.size).to eq(25)
    expect(rows.first.text).to include(quests.first.name)
    expect(rows.last.text).to include(quests.last.name)
    expect(response.body).to include("Showing 1–25 of 26", "Next page")
    expect(rows.text).not_to include(spectrum.name)

    get moderation_item_path(type: "Quest", id: quests.last.id), params: { queue_status: "pending", page: 1 }
    following = Nokogiri::HTML(response.body).at_css('[data-moderation-target="next"]')
    expect(following["href"]).to eq(moderation_item_path(type: "Spectrum", id: spectrum.id, queue_status: "pending", page: 2))

    get following["href"]
    expect(response.body).to include("26 of 26")
    previous = Nokogiri::HTML(response.body).at_css('[data-moderation-target="previous"]')
    expect(previous["href"]).to eq(moderation_item_path(type: "Quest", id: quests.last.id, queue_status: "pending", page: 1))

    get moderation_path, params: { page: 999 }
    expect(response.body).to include(spectrum.name, "Showing 26–26 of 26", "Previous page")
    get moderation_path, params: { page: -1 }
    expect(Nokogiri::HTML(response.body).css(".moderation-row").size).to eq(25)
  end

  it "includes achievements and highlights in the mixed queue and their type filters" do
    quest = create(:quest)
    achievement = create(:achievement, created_by: author, name: "Waiting achievement")
    highlight = create(:highlight, quest: quest, achievement: achievement, created_by: author)
    sign_in reviewer
    get moderation_path
    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css('[aria-label="Submission type"]').text).to include("All 2", "Achievements 1", "Highlights 1")
    expect(doc.css(".moderation-row").text).to include(achievement.name, "#{achievement.name} in #{quest.name}")
    get moderation_path, params: { item_type: "Highlight" }
    expect(Nokogiri::HTML(response.body).css(".moderation-row").size).to eq(1)
    expect(response.body).to include(moderation_item_path(type: "Highlight", id: highlight.id, queue_status: "pending", item_type: "Highlight", page: 1).gsub("&", "&amp;"))
    get moderation_path, params: { item_type: "Achievement" }
    expect(Nokogiri::HTML(response.body).css(".moderation-row").size).to eq(1)
    expect(response.body).not_to include("#{achievement.name} in #{quest.name}")
  end

  it "keeps queue filters through review and decision, and offers the next remaining item" do
    quest = create(:quest, created_by: author)
    next_quest = create(:quest, created_by: author)
    create(:spectrum, created_by: author)
    sign_in reviewer
    context = { queue_status: "pending", item_type: "Quest", page: 1 }
    patch moderation_item_path(type: "Quest", id: quest.id, **context),
      params: { decision: "approve", revision: 1, status: "pending" }
    expect(response).to redirect_to(moderation_item_path(type: "Quest", id: quest.id, **context))
    follow_redirect!
    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css('[data-moderation-target="next"]')["href"]).to eq(moderation_item_path(type: "Quest", id: next_quest.id, **context))
    expect(doc.at_css('[data-moderation-target="previous"]')).to be_nil
    expect(response.body).to include("Outside this queue")
    expect(quest.reload).to be_approved
  end

  it "shows provider key configuration from the web environment without exposing values" do
    quest = create(:quest, created_by: author)
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("TYPESAFE_API_KEY").and_return("private-fixture-key")
    allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return(nil)
    sign_in reviewer
    get moderation_item_path(type: "Quest", id: quest.id)
    providers = Nokogiri::HTML(response.body).at_css('[aria-label="AI provider configuration"]').text
    expect(providers).to include("Jev · Key configured", "OpenAI Luna · Key missing")
    expect(response.body).not_to include("private-fixture-key")
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
