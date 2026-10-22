require "rails_helper"

RSpec.describe "Shell search", type: :request do
  def search(query, side: "play")
    get search_path, params: { q: query, side: side }, headers: { "X-Requested-With" => "XMLHttpRequest" }
  end

  it "finds full player names and nicknames, including players without a current team" do
    player = create(:player, first_name: "Jalen", last_name: "Brunson", nicknames: [ "Big Body" ], team: nil)
    search "jalen brunson"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Jalen Brunson", player_path(player))
    search "BIG BODY"
    expect(response.body).to include("Jalen Brunson")
    expect(response.headers["Cache-Control"]).to include("no-store")
  end

  it "finds team abbreviations and competition abbreviations" do
    team = create(:team, territory: "New York", mascot: "Knicks", abbreviation: "NYK")
    league = team.league
    league.update! name: "National Basketball Association", abbreviation: "NBA"
    search "nyk"
    expect(response.body).to include("New York Knicks", team_path(team))
    search "nba"
    expect(response.body).to include("National Basketball Association", league_path(league))
  end

  it "limits groups and treats wildcard characters literally" do
    create_list(:player, 7, first_name: "Jalen")
    search "Jalen"
    expect(Nokogiri::HTML.fragment(response.body).css('[aria-label="Players"] a').size).to eq(5)
    create(:player, first_name: "Jalen_One", last_name: "Brunson")
    search "Jalen_"
    expect(response.body).to include("Jalen_One")
    expect(Nokogiri::HTML.fragment(response.body).css('[aria-label="Players"] a').size).to eq(1)
  end

  it "requires two characters, escapes unmatched input and bounds query length" do
    search "J"
    expect(response.body).to include("Enter at least 2 characters")
    search "<script>alert(1)</script>"
    expect(response.body).not_to include("<script>")
    expect(response.body).to include("&lt;script&gt;")
    search "z" * 200
    expect(response.body).to include("z" * 80)
    expect(response.body).not_to include("z" * 81)
  end

  it "keeps Feed results focused on players and teams and retains the originating side" do
    player = create(:player, first_name: "Riverside", last_name: "Carter")
    create(:city, name: "Riverside")
    search "Riverside", side: "feed"
    expect(response.body).to include(player_path(player, side: "feed"))
    expect(response.body).not_to include('aria-label="Cities"')
    search "Riverside"
    expect(response.body).to include('aria-label="Cities"')
  end

  it "does not expose account search or moderation data through a forged side" do
    author = create(:ace, username: "bleacher_sam", display_name: "Sam Carter")
    create(:quest, created_by: author, name: "Sam's private lineup")
    search "Sam", side: "admin"
    expect(response.body).not_to include("@bleacher_sam", "Sam's private lineup", author.email)
    sign_in create(:ace)
    search "Sam", side: "mod"
    expect(response.body).not_to include("@bleacher_sam", "Sam's private lineup", author.email)
    get ace_profile_path(author)
    expect(response).to have_http_status(:forbidden)
  end

  it "searches pending review items and aces while excluding self-review and decided items" do
    reviewer = create(:ace, moderator: true)
    author = create(:ace, username: "clutch_sam", display_name: "Sam Carter")
    quest = create(:quest, created_by: author, name: "Clutch starting five")
    create(:quest, created_by: reviewer, name: "Clutch own submission")
    create(:quest, name: "Clutch approved catalog")
    achievement = create(:achievement, name: "Clutch player")
    highlight = create(:highlight, created_by: author, quest: quest, achievement: achievement)
    sign_in reviewer
    search "Clutch", side: "mod"
    expect(response.body).to include("Clutch starting five", "@clutch_sam", "Highlight")
    expect(response.body).to include(moderation_item_path(type: "Highlight", id: highlight.id))
    expect(response.body).not_to include("Clutch own submission", "Clutch approved catalog", author.email)
    get ace_profile_path(author, side: "mod")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Sam Carter", "Recent submissions", "Clutch starting five")
    expect(response.body).not_to include(author.email)
  end

  it "lets admins find account identities, catalog data and existing settings" do
    admin = create(:ace, :admin)
    author = create(:ace, username: "wrigley_wes", display_name: "Wes Rivera")
    sign_in admin
    search "wrigley", side: "admin"
    expect(response.body).to include("Wes Rivera", "@wrigley_wes", ace_profile_path(author, side: "admin"))
    expect(response.body).not_to include(author.email)
    search "@wrigley_wes", side: "admin"
    expect(response.body).to include("Wes Rivera", "@wrigley_wes")
    search "settings", side: "admin"
    expect(response.body).to include("Account settings", edit_ace_registration_path)
    search "settings", side: "play"
    expect(response.body).not_to include("Account settings")
  end

  it "provides a full search page without JavaScript" do
    create(:player, first_name: "Jalen", last_name: "Brunson")
    get search_path, params: { q: "Brunson", side: "play" }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Jalen Brunson", "<html")
  end
end
