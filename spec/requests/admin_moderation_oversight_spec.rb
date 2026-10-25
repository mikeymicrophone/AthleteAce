require "rails_helper"
require "csv"

RSpec.describe "Admin moderation oversight", type: :request do
  include ActiveSupport::Testing::TimeHelpers
  around { |example| travel_to(Time.utc(2026, 10, 25, 12)) { example.run } }
  let(:admin) { create :ace, :admin }
  let(:quest) { create :quest, name: "Learn the Northern backcourt" }

  def event(action:, at:, from: nil)
    ModerationDecision.create! subject: quest, action: action, from_status: from,
      to_status: action == "submitted" || action == "reopened" ? "pending" : action,
      revision: 1, created_at: at, snapshot: { "name" => quest.name }
  end

  def document
    Nokogiri::HTML(response.body)
  end

  it "requires admin access and sends private no-store responses without writing decisions" do
    get admin_moderation_oversight_path
    expect(response).to redirect_to(new_ace_session_path)
    [ create(:ace), create(:ace, moderator: true) ].each do |viewer|
      sign_in viewer
      get admin_moderation_oversight_path
      expect(response).to redirect_to(root_path)
    end
    sign_in admin
    expect { get admin_moderation_oversight_path }.not_to change(ModerationDecision, :count)
    expect(response).to have_http_status(:ok)
    expect(response.headers["Cache-Control"]).to include("private", "no-store")
    expect(document.at_css("body")["data-side"]).to eq("admin")
    expect(document.css('.shell-sidebar a[aria-current="page"]').text).to include("Overview")
    expect(document.at_css('[data-oversight="total"]').text).to eq("0")
    expect(document.at_css('[data-oversight="wait"]').text).to eq("Not recorded")
    expect(response.body).to include("No recorded review events", "overturn rate is unavailable")
  end

  it "shows measured coverage, zero-day values and exact filtered drilldowns with matching CSV exports" do
    event action: "submitted", at: Time.utc(2026, 10, 20, 10)
    approved = event action: "approved", from: "pending", at: Time.utc(2026, 10, 20, 11)
    event action: "hidden", from: "approved", at: Time.utc(2026, 10, 22, 10)
    event action: "approved", at: Time.utc(2026, 10, 21, 10)
    sign_in admin
    get admin_moderation_oversight_path, params: { from: "2026-10-20", through: "2026-10-22", item_type: "Quest" }
    expect(response).to have_http_status(:ok)
    expect(document.at_css('[data-oversight="total"]').text).to eq("2")
    expect(document.at_css('[data-oversight="changes"]').text).to eq("1")
    expect(document.text).to include("1 of 1 decision pairs matched.")
    expect(document.css(".oversight-chart li").size).to eq(3)
    expect(document.css(".oversight-chart li")[1]["title"]).to eq("2026-10-21: 0 events")
    expect(document.css('.people-table tbody th').map(&:text)).to eq([ "Quests" ])
    link = document.at_css('a[aria-label="Quests approved: 1 events"]')
    get link["href"]
    expect(response).to have_http_status(:ok)
    expect(document.at_css('#reviews_only')["checked"]).to be_present
    expect(document.css(".moderation-list .moderation-row").size).to eq(1)
    export = document.at_css('a[href*=".csv"]')
    get export["href"]
    expect(CSV.parse(response.body, headers: true).map { |row| row["id"].to_i }).to eq([ approved.id ])
  end

  it "distinguishes zero-second waits from missing history" do
    at = Time.utc(2026, 10, 24, 10)
    event action: "submitted", at: at
    event action: "approved", from: "pending", at: at
    sign_in admin
    get admin_moderation_oversight_path
    expect(document.at_css('[data-oversight="wait"]').text).not_to eq("Not recorded")
    expect(document.text).to include("1 of 1 decision pairs matched.")
  end

  it "rejects invalid ranges and malformed filters without silently broadening the result" do
    sign_in admin
    [ { from: "2025-10-24" }, { from: "2026-10-26" }, { from: [ "2026-10-24" ] }, { through: { date: "2026-10-25" } }, { item_type: "Ace" }, { from: "2026-02-30" } ].each do |filters|
      get admin_moderation_oversight_path, params: filters
      expect(response).to have_http_status(:bad_request), filters.inspect
    end
  end

  it "keeps the new review-only flag through pagination and leaves the default log inclusive" do
    trusted = event action: "approved", at: Time.utc(2026, 10, 24, 9)
    26.times { event action: "approved", from: "pending", at: Time.utc(2026, 10, 24, 10) }
    sign_in admin
    get moderation_log_path, params: { reviews_only: "1", item_type: "Quest" }
    expect(document.css(".moderation-list .moderation-row").size).to eq(25)
    page_link = document.at_css('nav.pagy a[href*="page=2"]')
    expect(URI.parse(page_link["href"]).query).to include("reviews_only=1")
    get page_link["href"]
    expect(document.css(".moderation-list .moderation-row").size).to eq(1)
    get moderation_log_path(format: :csv), params: { reviews_only: "1", item_type: "Quest" }
    expect(CSV.parse(response.body, headers: true).map { |row| row["id"].to_i }).not_to include(trusted.id)
    get moderation_log_path(format: :csv), params: { item_type: "Quest" }
    expect(CSV.parse(response.body, headers: true).map { |row| row["id"].to_i }).to include(trusted.id)
    [ "0", "true", [ "1" ], { value: "1" } ].each do |value|
      get moderation_log_path, params: { reviews_only: value }
      expect(response).to have_http_status(:bad_request)
    end
  end
end
