require "rails_helper"

RSpec.describe "Weekly shout-out leaderboard", type: :request do
  include ActiveSupport::Testing::TimeHelpers
  let(:author) { create(:ace) }
  let(:reviewer) { create(:ace, moderator: true) }
  let(:team) { create(:team, league: create(:mlb)) }
  let(:first) { create(:player, team: team) }
  let(:second) { create(:player, team: team) }

  def publish(target, bid: 1)
    post = submit_credit(ace: author, target: target, bid: bid)
    review_post(post, action: "approve", reviewer: reviewer)
    post.reload
  end

  it "counts live approvals by UTC week, separates teams and computes movement using count/id ties" do
    old = nil
    travel_to Time.utc(2026, 10, 18, 23, 59, 59) do
      buy_credit(author)
      old = publish(first)
      2.times { publish(second) }
    end
    travel_to Time.utc(2026, 10, 19) do
      publish(first, bid: 2)
    end
    travel_to Time.utc(2026, 10, 22, 12) do
      2.times { publish(first, bid: 2) }
      publish(second, bid: 100)
      publish(team)
      pending = submit_credit(ace: author, target: first, bid: 1)
      rows = ShoutOutLeaderboard.new(week: "2026-10-22").rows
      expect(rows.map { |row| row.values_at(:id, :count, :rank, :movement) }).to eq([ [ first.id, 3, 1, 1 ], [ second.id, 1, 2, -1 ] ])
      expect(ShoutOutLeaderboard.new(kind: "teams").rows.map { |row| row[:count] }).to eq([ 1 ])
      expect(ShoutOutLeaderboard.new(week: "2026-10-18").rows.first.fetch(:id)).to eq(second.id)
      get shout_out_leaderboard_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Up 1", "Down 1", first.name)
      expect(response.body).not_to include(feed_post_path(pending))
      review_post(old, action: "hide", reviewer: reviewer)
      expect(ShoutOutLeaderboard.new(week: "2026-10-13").rows.map { |row| row[:id] }).not_to include(first.id)
    end
  end

  it "uses approval time and recorded league when a player transfers" do
    post = nil
    travel_to Time.utc(2026, 10, 18) do
      buy_credit(author)
      post = submit_credit(ace: author, target: first, bid: 1)
    end
    travel_to Time.utc(2026, 10, 22) do
      review_post(post, action: "approve", reviewer: reviewer)
      first.update!(team: create(:team, league: create(:nba)))
      get shout_out_leaderboard_path(league_id: team.league_id, sport_id: team.sport.id)
      expect(response.body).to include(first.name, "1 shout-out")
      get shout_out_leaderboard_path(league_id: team.league_id, sport_id: first.team.sport.id)
      expect(response.body).to include("No live shout-outs for this week.")
      expect(Nokogiri::HTML(response.body).at_css("select[name='league_id'] option[selected]")["value"]).to eq(team.league_id.to_s)
      expect(ShoutOutLeaderboard.new(week: "2026-10-13").rows).to be_empty
    end
  end

  it "supports empty weeks and rejects malformed, future and unsupported selections" do
    travel_to Time.utc(2026, 10, 22) do
      get shout_out_leaderboard_path(week: "2026-10-06")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No live shout-outs for this week.", "2026-10-05")
      [ { week: "bad" }, { week: "2026-02-30" }, { week: "2026-10-26" }, { week: [ "2026-10-19" ] }, { kind: "bids" } ].each do |params|
        get shout_out_leaderboard_path, params: params
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  it "paginates tied targets deterministically and omits deleted targets" do
    travel_to Time.utc(2026, 10, 22) do
      buy_credit(author)
      26.times { publish(create(:player, team: team)) }
      get shout_out_leaderboard_path(league_id: team.league_id)
      doc = Nokogiri::HTML(response.body)
      first_page = doc.css(".leaderboard-rows .identity-name").map { |node| node["href"] }
      expect(first_page.size).to eq(25)
      get shout_out_leaderboard_path(league_id: team.league_id, page: 2)
      second_page = Nokogiri::HTML(response.body).css(".leaderboard-rows .identity-name").map { |node| node["href"] }
      expect(second_page.size).to eq(1)
      expect(first_page & second_page).to be_empty
      target = Player.find(ShoutOutLeaderboard.new.rows.first.fetch(:id))
      target.destroy!
      expect(ShoutOutLeaderboard.new.rows.size).to eq(25)
    end
  end
end
