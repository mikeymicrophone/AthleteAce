require "rails_helper"

RSpec.describe "Funded shout-out submission and Feed" do
  let(:ace) { create(:ace) }
  let(:target) { create(:player, team: create(:team)) }

  it "submits only owned current drafts, reserves once, and ignores client moderation state" do
    buy_credit(ace)
    draft = ace.shout_out_drafts.create!(target: target, message: "An unforgettable finish")
    sign_in ace
    2.times do
      post shout_outs_path, params: { draft_id: draft.id, draft_revision: 0, bid: "2.50", payment_method: "credit", moderation_status: "approved", created_by_id: create(:ace).id }
      expect(response).to redirect_to(shout_out_path(ShoutOut.last))
    end
    expect(ShoutOut.count).to eq(1)
    expect(ShoutOut.last.moderation_status).to eq("pending")
    expect(CreditAccount.for(ace).reserved_cents).to eq(250)
    foreign = create(:ace).shout_out_drafts.create!(target: target, message: "Someone else's draft")
    post shout_outs_path, params: { draft_id: foreign.id, draft_revision: 0, bid: "1", payment_method: "credit" }
    expect(response).to have_http_status(:not_found)
  end

  it "shows live posts publicly and pending posts only to their owner, with hide refunds" do
    buy_credit(ace)
    post = submit_credit(ace: ace, target: target, message: "That was a spectacular finish")
    get feed_path
    expect(response.body).not_to include(post.message)
    sign_in ace
    get feed_path
    expect(response.body).to include(post.message, "in review")
    sign_out ace
    review_post(post, action: "approve")
    get feed_path
    expect(response.body).to include(post.message)
    review_post(post, action: "hide")
    get feed_path
    expect(response.body).not_to include(post.message)
    expect(CreditAccount.for(ace).available_cents).to eq(1000)
  end

  it "filters posts to preferred teams and keeps separate pagination stable" do
    buy_credit(ace)
    7.times do |index|
      post = submit_credit(ace: ace, target: target, message: "Memorable finish #{index}", bid: index + 1)
      review_post(post, action: "approve")
    end
    unrelated = submit_credit(ace: ace, target: create(:team), message: "Another league highlight")
    review_post(unrelated, action: "approve")
    ace.follows.create!(followable: target.team)
    sign_in ace
    get feed_path, params: { view: "my_teams", league_id: target.team.league_id }
    first_ids = Nokogiri::HTML(response.body).css(".shout-out-card").map { |node| node["id"] }
    expect(first_ids.size).to eq(5)
    expect(response.body).not_to include(unrelated.message)
    get feed_path, params: { view: "my_teams", league_id: target.team.league_id, posts_page: 2 }
    second_ids = Nokogiri::HTML(response.body).css(".shout-out-card").map { |node| node["id"] }
    expect(second_ids.size).to eq(2)
    expect(first_ids & second_ids).to be_empty
    get feed_path, params: { view: "my_teams", league_id: target.team.league_id }
    expect(Nokogiri::HTML(response.body).css(".shout-out-card").map { |node| node["id"] }).to eq(first_ids)
  end

  it "uses the exact dollar-based formula with per-visitor deterministic draws" do
    buy_credit(ace)
    posts = 8.times.map { |index| submit_credit(ace: ace, target: target, bid: 50 + index * 5) }
    expected = posts.sort_by do |post|
      draw = Digest::MD5.hexdigest("visitor-a:#{post.id}").first(13).to_i(16).fdiv(2**52)
      -((post.bid_cents / 100.0 + 0.5 + 2 * draw)**1.6)
    end
    ranked = ShoutOutFeed.ranked(ShoutOut.all, seed: "visitor-a").pluck(:id)
    expect(ranked).to eq(expected.map(&:id))
    expect(ShoutOutFeed.ranked(ShoutOut.all, seed: "visitor-b").pluck(:id)).not_to eq(ranked)
  end
end
