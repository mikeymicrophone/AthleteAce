require "rails_helper"

RSpec.describe "Player shout-outs", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:author) { create :ace }
  let(:reviewer) { create :ace, moderator: true }
  let(:player) { create :player, first_name: "Jordan", last_name: "Reyes" }

  def publish(target: player, message: "What a finish!", bid: 1)
    post = submit_credit(ace: author, target: target, message: message, bid: bid)
    review_post(post, action: "approve", reviewer: reviewer)
    post.reload
  end

  def preview_ids
    Nokogiri::HTML(response.body).css(".player-shout-outs .shout-out-card").map { |node| node["id"] }
  end

  it "shows three live previews in the same stable order as the full public list" do
    buy_credit author
    posts = 4.times.map { |i| publish(message: "A memorable play #{i}", bid: i + 1) }
    get player_path(player, side: "play")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("All player shout-outs", 'data-side="play"')
    expect(response.headers["Cache-Control"]).to include("private", "no-store")
    first_preview = preview_ids
    expect(first_preview.size).to eq(3)
    expect(first_preview - posts.map { |post| "shout_out_#{post.id}" }).to be_empty
    get player_path(player)
    expect(preview_ids).to eq(first_preview)
    get player_shout_outs_path(player)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-side="feed"')
    ids = Nokogiri::HTML(response.body).css(".shout-out-card").map { |node| node["id"] }
    expect(ids.first(3)).to eq(first_preview)
    expect(ids.size).to eq(4)
  end

  it "excludes pending, hidden, unfunded and other-target posts, including the author's own pending post" do
    buy_credit author
    live = publish(message: "Public appreciation")
    pending = submit_credit(ace: author, target: player, message: "Private while in review", bid: 1)
    hidden = publish(message: "Previously visible appreciation")
    review_post(hidden, action: "hide", reviewer: reviewer)
    draft = author.shout_out_drafts.create!(target: player, message: "Unpaid submission")
    unfunded = ShoutOutSubmission.call(draft: draft, revision: 0, bid_cents: 50, payment_method: "stripe")
    other = publish(target: create(:player), message: "Another athlete's post")
    team_post = publish(target: player.team, message: "Team appreciation")
    sign_in author
    [ player_path(player), player_shout_outs_path(player) ].each do |path|
      get path
      text = Nokogiri::HTML(response.body).text
      expect(text).to include(live.message)
      expect(text).not_to include(pending.message, hidden.message, unfunded.message, other.message, team_post.message)
    end
  end

  it "counts current live approvals in the UTC week rather than submission time or all-time previews" do
    old = pending = nil
    travel_to Time.utc(2026, 10, 18, 23, 59, 59) do
      buy_credit author
      old = publish(message: "Last week's live post")
      pending = submit_credit(ace: author, target: player, message: "Approved in the next week", bid: 1)
    end
    travel_to Time.utc(2026, 10, 19, 0, 0, 0) do
      review_post(pending, action: "approve", reviewer: reviewer)
      get player_path(player)
      expect(Nokogiri::HTML(response.body).text).to include("1 live shout-out approved this week · UTC", old.message, pending.message)
      review_post(pending.reload, action: "hide", reviewer: reviewer)
      get player_path(player)
      expect(Nokogiri::HTML(response.body).text).to include("0 live shout-outs approved this week · UTC", old.message)
      expect(response.body).not_to include(pending.message)
    end
  end

  it "keeps player-specific posts after a transfer and ignores alternate target parameters" do
    buy_credit author
    post = publish
    player.update! team: create(:team)
    other = publish(target: create(:player), message: "A different athlete")
    get player_shout_outs_path(player, target_id: other.target_id, target_type: "Team")
    expect(response.body).to include(post.message)
    expect(response.body).not_to include(other.message)
  end

  it "paginates without duplicates and keeps only the player's posts on subsequent pages" do
    buy_credit author
    posts = 26.times.map { |i| publish(message: "Courtside appreciation #{i}") }
    get player_shout_outs_path(player)
    doc = Nokogiri::HTML(response.body)
    first = doc.css(".shout-out-card").map { |node| node["id"] }
    expect(first.size).to eq(25)
    next_page = doc.css("a").find { |node| node["href"]&.include?("page=2") }
    expect(next_page["href"]).to include("/players/#{player.id}/shout_outs")
    get next_page["href"]
    second = Nokogiri::HTML(response.body).css(".shout-out-card").map { |node| node["id"] }
    expect(second.size).to eq(1)
    expect(first & second).to be_empty
    expect(first + second).to match_array(posts.map { |post| "shout_out_#{post.id}" })
  end

  it "has public empty states without exposing private submission routes" do
    get player_path(player)
    expect(response.body).to include("No live shout-outs for this player yet.", "0 live shout-outs")
    get player_shout_outs_path(player)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("No live shout-outs yet.")
    get shout_outs_path
    expect(response).to redirect_to(new_ace_session_path)
  end
end
