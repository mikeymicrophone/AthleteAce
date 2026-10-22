require "rails_helper"

RSpec.describe "Public shout-out search", type: :request do
  let(:author) { create(:ace, username: "courtside_nico", display_name: "Nico's Fan") }

  it "finds live messages, recorded targets and public handles without exposing moderation data" do
    buy_credit(author)
    target = create(:player, first_name: "Nico", last_name: "Hoerner")
    live = submit_credit(ace: author, target: target, message: "One hundred percent effort", bid: 1)
    pending = submit_credit(ace: author, target: target, message: "Secret hundred percent draft", bid: 1)
    hidden = submit_credit(ace: author, target: target, message: "Hidden hundred percent", bid: 1)
    [ live, hidden ].each { |post| review_post(post, action: "approve") }
    review_post(hidden, action: "hide")
    live.shout_out_reports.create!(reporter: create(:ace), reason: "Spam", note: "Invisible report evidence")
    get search_path(side: "feed", q: "percent")
    expect(response.body).to include(live.message, feed_post_path(live))
    expect(response.body).not_to include(pending.message, hidden.message, "Invisible report evidence", author.email)
    expect(response.body).not_to include(moderation_item_path(type: "ShoutOut", id: live.id))
    get feed_path(q: "@courtside_nico")
    expect(response.body).to include(live.message)
    get feed_path(q: "Hoerner")
    expect(response.body).to include(live.message)
    sign_in author
    get feed_path(q: "percent")
    expect(response.body).to include(live.message)
    expect(response.body).not_to include(pending.message, hidden.message)
    get feed_post_path(pending)
    expect(response).to have_http_status(:not_found)
    get shout_out_path(pending)
    expect(response).to have_http_status(:ok)
  end

  it "escapes SQL wildcards, preserves My teams scope and removes hidden search results immediately" do
    buy_credit(author)
    team = create(:team)
    target = create(:player, team: team)
    selected = submit_credit(ace: author, target: target, message: "100% hustle", bid: 1)
    unrelated = submit_credit(ace: author, target: create(:team), message: "100 percent hustle", bid: 1)
    [ selected, unrelated ].each { |post| review_post(post, action: "approve") }
    get feed_path(q: "100%")
    expect(response.body).to include(selected.message)
    expect(response.body).not_to include(unrelated.message)
    viewer = create(:ace)
    viewer.follows.create!(followable: team)
    sign_in viewer
    get feed_path(view: "my_teams", q: "hustle")
    expect(response.body).to include(selected.message)
    expect(response.body).not_to include(unrelated.message)
    get feed_path(q: "x")
    expect(response).to have_http_status(:bad_request)
    review_post(selected, action: "hide")
    get search_path(side: "feed", q: "100%")
    expect(response.body).not_to include(feed_post_path(selected))
  end
end
