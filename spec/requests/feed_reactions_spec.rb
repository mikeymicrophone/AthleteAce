require "rails_helper"

RSpec.describe "Live shout-out reactions", type: :request do
  let(:author) { create(:ace) }
  let(:fan) { create(:ace) }
  let(:live_post) do
    buy_credit(author)
    post = submit_credit(ace: author, target: create(:player), bid: 125)
    review_post(post, action: "approve")
    post.reload
  end

  it "adds and removes each free membership idempotently without touching another ace or money" do
    post = live_post
    get feed_post_path(post)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Sign in to react Fire, 0")
    put shout_out_shout_out_reaction_path(post, "fire")
    expect(response).to redirect_to(new_ace_session_path)
    sign_in fan
    money = CreditEntry.count
    2.times do
      put shout_out_shout_out_reaction_path(post, "fire"), params: { ace_id: author.id, kind: "love" }
      expect(response).to have_http_status(:see_other)
    end
    expect(post.shout_out_reactions.pluck(:ace_id, :kind)).to eq([ [ fan.id, "fire" ] ])
    post.shout_out_reactions.create!(ace: author, kind: "fire")
    %w[love legend].each { |kind| put shout_out_shout_out_reaction_path(post, kind) }
    get feed_post_path(post)
    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css('button[aria-label="Fire, 2"]')["aria-pressed"]).to eq("true")
    2.times { delete shout_out_shout_out_reaction_path(post, "fire") }
    expect(post.shout_out_reactions.where(kind: "fire").pluck(:ace_id)).to eq([ author.id ])
    expect(CreditEntry.count).to eq(money)
    expect(post.reload.funding_status).to eq("spent")
  end

  it "returns a Turbo card with fresh totals and rejects invalid kinds and non-live posts" do
    post = live_post
    sign_in fan
    put shout_out_shout_out_reaction_path(post, "love"), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('target="shout_out_', 'aria-label="Love, 1"', 'aria-pressed="true"')
    put shout_out_shout_out_reaction_path(post, "unsupported")
    expect(response).to have_http_status(:bad_request)
    pending = submit_credit(ace: author, target: post.target, bid: 1)
    put shout_out_shout_out_reaction_path(pending, "fire")
    expect(response).to have_http_status(:not_found)
    review_post(post, action: "hide")
    delete shout_out_shout_out_reaction_path(post, "love")
    expect(response).to have_http_status(:not_found)
    get feed_post_path(post)
    expect(response).to have_http_status(:not_found)
  end

  it "summarizes counts and the viewer's selected kinds across a page" do
    post = live_post
    post.shout_out_reactions.create!(ace: fan, kind: "legend")
    post.shout_out_reactions.create!(ace: author, kind: "legend")
    summary = ShoutOutReactionSummary.new(posts: [ post ], ace: fan)
    expect(summary.count(post, "legend")).to eq(2)
    expect(summary.count(post, "love")).to eq(0)
    expect(summary.selected?(post, "legend")).to be(true)
    expect(ShoutOutReactionSummary.new(posts: [ post ], ace: nil).selected?(post, "legend")).to be(false)
    expect { post.shout_out_reactions.create!(ace: fan, kind: "legend") }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "keeps HTML redirects local and removes memberships when the reacting account is deleted" do
    post = live_post
    sign_in fan
    put shout_out_shout_out_reaction_path(post, "fire"), headers: { "Referer" => "https://example.net/outside" }
    expect(response).to redirect_to(feed_post_path(post))
    delete ace_registration_path
    expect(Ace.exists?(fan.id)).to be(false)
    expect(post.shout_out_reactions.count).to eq(0)
    get feed_post_path(post)
    expect(response.body).to include("Sign in to react Fire, 0")
  end
end
