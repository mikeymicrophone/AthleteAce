require "rails_helper"

RSpec.describe "Application shell", type: :request do
  def document
    Nokogiri::HTML(response.body)
  end

  def side_labels
    document.css('[aria-label="Switch sides"] a').map { |link| link["aria-label"] }
  end

  it "lands visitors on Feed and keeps Play available as a preview" do
    get root_path
    expect(response).to redirect_to(feed_path)
    follow_redirect!
    expect(document.at_css("body")["data-side"]).to eq("feed")
    expect(side_labels).to eq(%w[Play Feed])
    expect(response.body).to include("Preview", "Reading is open to everyone", "No shout-outs yet.")
    get strength_path
    get root_path
    expect(response).to redirect_to(feed_path)
  end

  it "lands fans on Play and does not expose privileged sides through parameters" do
    sign_in create(:ace)
    get feed_path
    get root_path
    expect(response).to redirect_to(strength_path)
    get browse_path, params: { side: "admin" }
    expect(side_labels).to eq(%w[Play Feed])
    expect(document.at_css("body")["data-side"]).to eq("play")
    expect(response.body).not_to include(admin_path + '"', moderation_path + '"')
  end

  it "remembers a moderator's side on shared pages and at the root" do
    sign_in create(:ace, moderator: true)
    player = create(:player, first_name: "Jalen", last_name: "Brunson")
    get root_path
    expect(response).to redirect_to(moderation_path)
    get moderation_path
    expect(side_labels).to eq(%w[Play Feed Moderate])
    get player_path(player)
    expect(document.at_css("body")["data-side"]).to eq("mod")
    get root_path
    expect(response).to redirect_to(moderation_path)
    get feed_path
    get player_path(player)
    expect(document.at_css("body")["data-side"]).to eq("feed")
    get root_path
    expect(response).to redirect_to(feed_path)
    get strength_path
    get root_path
    expect(response).to redirect_to(strength_path)
  end

  it "keeps JSON and Turbo Frame requests from replacing the saved side" do
    sign_in create(:ace, moderator: true)
    get moderation_path
    get strength_path, headers: { "Turbo-Frame" => "practice" }
    get root_path
    expect(response).to redirect_to(moderation_path)
    get players_path(format: :json)
    get root_path
    expect(response).to redirect_to(moderation_path)
  end

  it "gates Admin and shows real application totals to admins" do
    admin = create(:ace, :admin)
    create(:player)
    sign_in admin
    get root_path
    expect(response).to redirect_to(admin_path)
    follow_redirect!
    expect(side_labels).to eq(%w[Play Feed Moderate Admin])
    expect(document.at_css('[aria-label="Application totals"]').text).to include("Aces", "Players", "Teams", "Waiting review")
    get browse_path, params: { section: "content", side: "admin" }
    expect(document.at_css("body")["data-side"]).to eq("admin")
    expect(document.css(".shell-browse-link").map { |link| link.text.squish }).to include("Quests", "Spectrums")
    sign_out admin
    sign_in create(:ace, moderator: true)
    get admin_path
    expect(response).to redirect_to(root_path)
    expect(response.body).not_to include("Application totals")
    sign_out :ace
    get admin_path
    expect(response).to redirect_to(new_ace_session_path)
  end

  it "counts only reviewable pending items in the Moderate badge" do
    reviewer = create(:ace, moderator: true)
    author = create(:ace)
    create(:quest, created_by: author)
    create(:spectrum, created_by: author)
    own = create(:quest, created_by: reviewer)
    sign_in reviewer
    get feed_path
    badge = document.at_css('[aria-label="Switch sides"] [data-side="mod"] .shell-badge')
    expect(badge.text).to eq("2")
    expect(badge["aria-label"]).to eq("2 submissions waiting")
    Quest.where.not(id: own.id).update_all(moderation_status: "approved")
    Spectrum.update_all(moderation_status: "approved")
    get feed_path
    expect(document.at_css('[aria-label="Switch sides"] [data-side="mod"] .shell-badge')).to be_nil
  end

  it "stores a signed-in ace's theme without changing another account or accepting roles" do
    ace = create(:ace)
    other = create(:ace)
    sign_in ace
    patch theme_preference_path, params: { theme: "dark", ace_id: other.id, admin: true }, headers: { "Referer" => strength_url }
    expect(response).to redirect_to(strength_path)
    expect(ace.reload.theme).to eq("dark")
    expect(ace).not_to be_admin
    expect(other.reload.theme).to eq("system")
    get feed_path
    expect(document.at_css("html")["data-theme"]).to eq("dark")
    patch theme_preference_path, params: { theme: "untrusted" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(ace.reload.theme).to eq("dark")
  end

  it "stores a visitor's theme in a cookie and keeps it separate from account preferences" do
    patch theme_preference_path, params: { theme: "light" }
    expect(response).to have_http_status(:see_other)
    get feed_path
    expect(document.at_css("html")["data-theme"]).to eq("light")
    ace = create(:ace, theme: "dark")
    sign_in ace
    get feed_path
    expect(document.at_css("html")["data-theme"]).to eq("dark")
    sign_out ace
    get feed_path
    expect(document.at_css("html")["data-theme"]).to eq("light")
  end

  it "keeps a saved shared-page destination through sign-in" do
    ace = create(:ace)
    player = create(:player)
    get player_path(player)
    post ace_session_path, params: { ace: { email: ace.email, password: "password123" } }
    expect(response).to redirect_to(player_path(player))
  end
end
