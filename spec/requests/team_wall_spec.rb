require "rails_helper"

RSpec.describe "Team wall", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:ace) { create(:ace) }
  let(:team) { create(:team) }

  it "filters public team and player posts by immutable team context, keeping pending posts private" do
    buy_credit(ace)
    player = create(:player, team: team)
    team_post = submit_credit(ace: ace, target: team, message: "The whole team showed up")
    player_post = submit_credit(ace: ace, target: player, message: "Brilliant final play")
    pending = submit_credit(ace: ace, target: team, message: "Private until reviewed")
    [ team_post, player_post ].each { |post| review_post(post, action: "approve") }
    player.update!(team: create(:team))
    get team_path(team, side: "feed")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(team_post.message, player_post.message, 'data-side="feed"')
    expect(response.body).not_to include(pending.message)
    get team_path(team, wall_filter: "team")
    expect(response.body).to include(team_post.message)
    expect(response.body).not_to include(player_post.message)
    get team_path(team, wall_filter: "players")
    expect(response.body).to include(player_post.message)
    expect(response.body).not_to include(team_post.message)
    review_post(player_post.reload, action: "hide")
    get team_path(team, wall_filter: "players")
    expect(response.body).not_to include(player_post.message)
  end

  it "retains tabs, side, filtering and stable ranking across pagination with safe empty states" do
    get team_path(team, wall_filter: "bogus")
    expect(response).to have_http_status(:bad_request)
    get team_path(team, tab: "bogus")
    expect(response).to have_http_status(:bad_request)
    get team_path(team)
    expect(response.body).to include("No shout-outs here yet.")
    player = create(:player, team: team)
    get team_path(team, tab: "roster", side: "play")
    expect(response.body).to include(player.name)
    expect(response.body).to include("tab=ratings", "side=play")
    get team_path(team, tab: "ratings", side: "play")
    expect(response.body).to include("How aces rate")
  end

  it "paginates a stable weighted wall while preserving the nested route and filters" do
    buy_credit(ace)
    reviewer = create(:ace, moderator: true)
    26.times do |index|
      post = submit_credit(ace: ace, target: team, message: "Team highlight #{index}", bid: 1)
      review_post(post, action: "approve", reviewer: reviewer)
    end
    destination = league_team_path(team.league, team, side: "feed", tab: "wall", wall_filter: "team")
    get destination
    expect(response).to have_http_status(:ok)
    first = Nokogiri::HTML(response.body).css(".shout-out-card").map { |card| card["id"] }
    links = Nokogiri::HTML(response.body).css("a").map { |link| link["href"] }
    next_page = links.find { |link| link&.include?("page=2") }
    expect(next_page).to include("wall_filter=team", "side=feed", "/leagues/#{team.league_id}/teams/#{team.id}")
    get next_page
    second = Nokogiri::HTML(response.body).css(".shout-out-card").map { |card| card["id"] }
    expect(first & second).to be_empty
    expect((first + second).uniq.size).to eq(26)
    get destination
    expect(Nokogiri::HTML(response.body).css(".shout-out-card").map { |card| card["id"] }).to eq(first)
  end

  it "counts the week a post was approved rather than the week its draft was submitted" do
    post = nil
    travel_to Time.utc(2026, 10, 18, 12) do
      buy_credit(ace)
      post = submit_credit(ace: ace, target: create(:player, team: team), bid: 1)
    end
    travel_to Time.utc(2026, 10, 22, 12) do
      review_post(post, action: "approve")
      get team_path(team)
      expect(response.body).to include("1 live shout-out this week", post.target_name)
    end
  end
end
