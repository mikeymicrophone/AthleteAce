require "rails_helper"

RSpec.describe "Admin overview", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  it "requires an admin and shows private zero-state operational metrics" do
    get admin_path
    expect(response).to redirect_to(new_ace_session_path)
    [ create(:ace), create(:ace, moderator: true) ].each do |viewer|
      sign_in viewer
      get admin_path
      expect(response).to redirect_to(root_path)
      expect(response.body).not_to include("Cash purchases today")
    end
    sign_in create(:ace, :admin)
    get admin_path
    expect(response).to have_http_status(:ok)
    expect(response.headers["Cache-Control"]).to include("private", "no-store")
    document = Nokogiri::HTML(response.body)
    expect(document.at_css('[data-overview="cash"]').text).to eq("$0.00")
    expect(document.at_css('[data-overview="reviews"]').text).to eq("0")
    expect(document.css("[data-cash-date]").length).to eq(14)
    expect(response.body).to include("No recorded review events today.", "No open escalations you can view.", "UTC")
    expect(response.body).not_to include("Last seed", "Median decision", "target 60m")
  end

  it "uses UTC boundaries, actual purchase ledger entries and review transitions instead of submissions or trusted creation" do
    today = Time.utc(2026, 10, 24, 12)
    admin = create(:ace, :admin, created_at: today - 2.days)
    author = create(:ace, created_at: today - 2.days)
    reviewer = create(:ace, moderator: true, display_name: "Rae Carter", created_at: today - 2.days)
    former = create(:ace, moderator: true, created_at: today - 2.days)
    travel_to today.beginning_of_day - 1.second do
      buy_credit(author, amount: 100)
      quest = create(:quest, created_by: author)
      Moderation::Review.call(record: quest, actor: reviewer, action: "approve", revision: 1, status: "pending")
    end
    travel_to today.beginning_of_day do
      buy_credit(author, amount: 200)
    end
    travel_to today + 1.hour do
      buy_credit(author, amount: 1000)
      create(:ace)
    end
    travel_to today do
      buy_credit(author, amount: 300)
      post = submit_credit(ace: author, target: create(:player), bid: 250)
      review_post(post, action: "approve", reviewer: reviewer)
      review_post(post, action: "hide", reviewer: reviewer)
      create(:quest, created_by: author)
      create(:quest, created_by: admin, moderation_status: "approved")
      trusted = create(:quest, name: "Trusted roster guide")
      trusted.moderation_editor = admin
      trusted.update!(name: "Updated trusted roster guide")
      quest = create(:quest, created_by: author)
      Moderation::Review.call(record: quest, actor: former, action: "reject", revision: 1, status: "pending", reason: "Needs revision")
      former.destroy!
      create(:ace, :unconfirmed)
      sign_in admin
      Time.use_zone("Pacific/Honolulu") { get admin_path }
      document = Nokogiri::HTML(response.body)
      expect(document.at_css('[data-overview="cash"]').text).to eq("$5.00")
      expect(document.at_css('[data-overview="accounts"]').text).to eq("1")
      expect(document.at_css('[data-overview="reviews"]').text).to eq("3")
      expect(document.at_css('[data-cash-date="2026-10-23"]').text).to include("$1.00")
      expect(document.at_css('[data-cash-date="2026-10-24"]').text).to include("$5.00", "today")
      expect(document.at_css(".admin-cash").text).to include("$6.00")
      expect(document.at_css(".admin-review-counts").text).to include("Rae Carter", "2 events", "System or deleted account", "1 event")
      expect(document.css("[data-cash-date]").map { |node| node["data-cash-date"] }).to eq((Date.new(2026, 10, 11)..Date.new(2026, 10, 24)).map(&:iso8601))
    end
  end

  it "shows the five oldest visible open escalations, including deleted subjects, and excludes own or resolved cases" do
    admin = create(:ace, :admin)
    author = create(:ace)
    reviewer = create(:ace, moderator: true)
    escalate = lambda do |subject, actor = reviewer|
      Moderation::Escalate.call(subject: subject, actor: actor, reason: "Private handoff context", request_key: SecureRandom.uuid,
        revision: subject.is_a?(Ace) ? nil : subject.moderation_revision, status: subject.is_a?(Ace) ? nil : subject.moderation_status)
    end
    cases = 6.times.map { |index| escalate.call(create(:quest, created_by: author, name: "Visible case #{index}")) }
    cases.first.subject.destroy!
    escalate.call(create(:quest, created_by: admin, moderation_status: "pending", name: "Own private submission"))
    escalate.call(admin)
    resolved = escalate.call(create(:quest, created_by: author, name: "Resolved handoff"))
    Moderation::ResolveEscalation.call(escalation: resolved, actor: admin, resolution: "no_change", reason: "Reviewed", version: 0)
    sign_in admin
    expect { get admin_path }.not_to change(ModerationDecision, :count)
    document = Nokogiri::HTML(response.body)
    expect(document.at_css('[data-overview="escalations"]').text).to eq("6")
    expect(document.css(".admin-escalation-list h3").map(&:text)).to eq(5.times.map { |index| "Visible case #{index}" })
    expect(document.css(".admin-escalation-list a").map { |node| node["href"] }).to eq(cases.first(5).map { |record| escalation_path(record) })
    expect(response.body).not_to include("Own private submission", "Resolved handoff", "Private handoff context", "Visible case 5")
  end
end
