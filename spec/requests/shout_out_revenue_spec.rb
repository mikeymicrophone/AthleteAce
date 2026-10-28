require "rails_helper"
require "csv"

RSpec.describe "Shout-out revenue", type: :request do
  include ActiveSupport::Testing::TimeHelpers
  let(:admin) { create(:ace, admin: true) }

  it "protects HTML and CSV from ordinary aces and moderators" do
    get shout_out_revenue_path
    expect(response).to redirect_to(new_ace_session_path)
    [ create(:ace), create(:ace, moderator: true) ].each do |ace|
      sign_in ace
      [ nil, :csv ].each do |format|
        get shout_out_revenue_path(format: format)
        expect(response).not_to have_http_status(:ok)
      end
    end
    sign_in admin
    get shout_out_revenue_path(days: "0")
    expect(response).to have_http_status(:bad_request)
  end

  it "keeps purchases, approvals, rejected reservations and refunds distinct and exports exact daily cents" do
    travel_to Time.utc(2026, 10, 22, 12) do
      ace = create(:ace)
      buy_credit(ace, amount: 1234)
      first = submit_credit(ace: ace, target: create(:player), bid: 101)
      review_post(first, action: "approve")
      second = submit_credit(ace: ace, target: first.target, bid: 33)
      review_post(second, action: "reject")
      review_post(first.reload, action: "hide")
      totals = ShoutOutRevenue.new(days: "7")
      expect(totals.totals).to eq("purchase" => 1234, "capture" => 101, "release" => 33, "refund" => 101)
      expect(totals.balances).to eq([ 1234, 0 ])
      sign_in admin
      get shout_out_revenue_path(days: 7)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("$12.34", "Card fees and net cash are unavailable", "today so far")
      expect(response.headers["Cache-Control"]).to include("no-store")
      get shout_out_revenue_path(days: 7, format: :csv)
      expect(response).to have_http_status(:ok)
      csv = CSV.parse(response.body, headers: true)
      expect(csv.size).to eq(7)
      expect(csv[-1].fields).to eq(%w[2026-10-22 1234 101 33 101])
    end
  end

  it "uses inclusive UTC calendar boundaries and reports refunds in their actual period" do
    ace = create(:ace)
    post = nil
    travel_to Time.utc(2026, 10, 15, 23, 59, 59) do
      buy_credit(ace, amount: 200)
      post = submit_credit(ace: ace, target: create(:player), bid: 50)
      review_post(post, action: "approve")
    end
    travel_to(Time.utc(2026, 10, 16)) { buy_credit(ace, amount: 99) }
    travel_to Time.utc(2026, 10, 22, 12) do
      review_post(post.reload, action: "hide")
      revenue = ShoutOutRevenue.new(days: 7)
      expect(revenue.totals).to eq("purchase" => 99, "capture" => 0, "release" => 0, "refund" => 50)
      expect(revenue.top_targets).to be_empty
      expect(revenue.paying_aces).to eq(1)
    end
  end
end
