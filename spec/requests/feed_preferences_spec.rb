require "rails_helper"

RSpec.describe "My teams on Feed", type: :request do
  let(:ace) { create(:ace) }
  let!(:team) { create(:team, territory: "Chicago", mascot: "Cubs") }
  let!(:other) { create(:team, league: team.league, territory: "Detroit", mascot: "Tigers") }

  def team_cards
    Nokogiri::HTML(response.body).css(".feed-team-card")
  end

  it "keeps visitors' personalized view private and offers sign-in" do
    ace.follows.create!(followable: team)
    get feed_path, params: { view: "my_teams", ace_id: ace.id }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Sign in to see teams", "Try one Team Match question")
    expect(response.body).not_to include("No shout-outs yet.")
    expect(team_cards).to be_empty
    expect(response.body).not_to include(team.name)
  end

  it "shows only owned preferences and labels overlapping sources without duplicate teams" do
    ace.follows.create!(followable: team)
    create(:ace).follows.create!(followable: other)
    affinity = create(:spectrum, name: "Affinity")
    create(:rating, ace: ace, spectrum: affinity, target: team, value: 5000)
    create(:rating, ace: create(:ace), spectrum: affinity, target: other, value: 10_000)
    sign_in ace
    get feed_path, params: { view: "my_teams", ace_id: create(:ace).id }
    expect(response).to have_http_status(:ok)
    expect(team_cards.size).to eq(1)
    expect(team_cards.sole.text).to include(team.name, "Following", "High Affinity")
    expect(response.body).not_to include(other.name, "Try one Team Match question")
    link = team_cards.sole.at_css('a[aria-label^="Practice"]')
    expect(link["href"]).to eq(new_game_round_path(team_id: team.id))
  end

  it "includes high Affinity teams without follows but excludes lower, archived and hidden ratings" do
    affinity = create(:spectrum, name: "Affinity")
    rating = create(:rating, ace: ace, spectrum: affinity, target: team, value: 5000)
    create(:rating, ace: ace, spectrum: affinity, target: other, value: 4999)
    sign_in ace
    get feed_path, params: { view: "my_teams" }
    expect(team_cards.map { |card| card["aria-label"] }).to eq([ team.name ])
    rating.update!(archived: true)
    get feed_path, params: { view: "my_teams" }
    expect(team_cards).to be_empty
    rating.update!(archived: false)
    affinity.update!(moderation_status: "hidden")
    get feed_path, params: { view: "my_teams" }
    expect(team_cards).to be_empty
  end

  it "intersects the chosen league and never fills an empty view with unrelated teams" do
    ace.follows.create!(followable: team)
    separate = create(:team)
    ace.follows.create!(followable: separate)
    sign_in ace
    get feed_path, params: { view: "my_teams", league_id: team.league_id }
    expect(team_cards.map { |card| card["aria-label"] }).to eq([ team.name ])
    get feed_path, params: { view: "my_teams", league_id: create(:league).id }
    expect(team_cards).to be_empty
    expect(response.body).to include("No teams match this view.", "Clear filters")
    get feed_path, params: { view: "my_teams", league_id: -1 }
    expect(response).to have_http_status(:not_found)
  end

  it "does not infer followed teams from player follows" do
    ace.follows.create!(followable: create(:player, team: team))
    sign_in ace
    get feed_path, params: { view: "my_teams" }
    expect(team_cards).to be_empty
    expect(response.body).to include("No teams match this view.")
  end

  it "paginates the personal list and retains view and league in page links" do
    6.times { ace.follows.create!(followable: create(:team, league: team.league)) }
    sign_in ace
    get feed_path, params: { view: "my_teams", league_id: team.league_id }
    expect(team_cards.size).to eq(5)
    link = Nokogiri::HTML(response.body).css("a[href]").find { |node| URI.parse(node["href"]).query.to_s.include?("page=2") }
    query = Rack::Utils.parse_nested_query(URI.parse(link["href"]).query)
    expect(query).to include("view" => "my_teams", "league_id" => team.league_id.to_s)
    get link["href"]
    expect(team_cards.size).to eq(1)
  end

  it "keeps All as the default and rejects unknown views" do
    sign_in ace
    ace.follows.create!(followable: team)
    get feed_path
    expect(response).to have_http_status(:ok)
    expect(team_cards).to be_empty
    expect(response.body).to include("Latest", "No shout-outs yet.")
    get feed_path, params: { view: "other_account" }
    expect(response).to have_http_status(:bad_request)
  end
end
