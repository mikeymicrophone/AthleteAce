require "rails_helper"

RSpec.describe Admin::ModerationOversight do
  include ActiveSupport::Testing::TimeHelpers
  around { |example| travel_to(Time.utc(2026, 10, 25, 12)) { example.run } }

  let(:quest) { create :quest, id: 9001, name: "Learn the Northern backcourt" }

  def event(action:, at:, revision: 1, subject: quest, from: nil, to: nil)
    ModerationDecision.create! subject: subject, actor: nil, action: action, revision: revision,
      from_status: from, to_status: to || (action == "reopened" || action == "submitted" ? "pending" : action),
      created_at: at, snapshot: { "name" => subject.name }
  end

  it "counts only recorded review transitions and fills zero UTC dates through the as-of time" do
    event action: "approved", from: "pending", at: Time.utc(2026, 10, 23, 23, 59, 59)
    event action: "rejected", from: "pending", at: Time.utc(2026, 10, 25, 0)
    event action: "hidden", from: "approved", at: Time.utc(2026, 10, 25, 13)
    event action: "approved", from: nil, at: Time.utc(2026, 10, 24, 10)
    event action: "approved", from: "approved", at: Time.utc(2026, 10, 24, 11)
    event action: "hidden", from: "pending", at: Time.utc(2026, 10, 24, 11)
    event action: "submitted", from: "approved", at: Time.utc(2026, 10, 24, 11)
    stats = described_class.new(from: "2026-10-23", through: "2026-10-25")
    expect(stats.counts).to eq("approved" => 1, "rejected" => 1)
    expect(stats.daily).to eq(Date.new(2026, 10, 23) => 1, Date.new(2026, 10, 24) => 0, Date.new(2026, 10, 25) => 1)
    expect(stats.by_type).to eq([ "Quest", "approved" ] => 1, [ "Quest", "rejected" ] => 1)
  end

  it "measures separate pending cycles on a revision and can use a start before the date range" do
    event action: "submitted", at: Time.utc(2026, 10, 19, 10)
    event action: "rejected", from: "pending", at: Time.utc(2026, 10, 20, 10)
    event action: "reopened", from: "rejected", at: Time.utc(2026, 10, 21, 10)
    event action: "approved", from: "pending", at: Time.utc(2026, 10, 21, 12)
    stats = described_class.new(from: "2026-10-20", through: "2026-10-21")
    expect(stats.pending_wait).to eq(matched: 2, total: 2, median_seconds: 13.hours.to_f)
    expect(stats.counts).to eq("rejected" => 1, "reopened" => 1, "approved" => 1)
  end

  it "does not invent waits for missing, inconsistent or different-revision pairs" do
    event action: "submitted", at: Time.utc(2026, 10, 20, 10)
    event action: "approved", from: "pending", at: Time.utc(2026, 10, 20, 11)
    event action: "approved", from: "pending", at: Time.utc(2026, 10, 20, 12)
    event action: "rejected", from: "pending", revision: 2, at: Time.utc(2026, 10, 20, 13)
    event action: "submitted", revision: 3, at: Time.utc(2026, 10, 20, 14)
    event action: "approved", from: "pending", revision: 4, at: Time.utc(2026, 10, 20, 15)
    event action: "reopened", from: "approved", revision: 5, at: Time.utc(2026, 10, 20, 16)
    event action: "approved", from: "pending", revision: 5, at: Time.utc(2026, 10, 20, 17)
    stats = described_class.new
    expect(stats.pending_wait).to eq(matched: 1, total: 5, median_seconds: 1.hour.to_f)
  end

  it "uses event ids for equal timestamps and retains genuine zero-second waits" do
    at = Time.utc(2026, 10, 24, 10)
    event action: "submitted", at: at
    event action: "approved", from: "pending", at: at
    expect(described_class.new.pending_wait).to eq(matched: 1, total: 1, median_seconds: 0.0)
  end

  it "keeps types and subject ids separate and filters by the decision's content type" do
    spectrum = create :spectrum, id: 9001, name: "Composure"
    event action: "submitted", at: Time.utc(2026, 10, 24, 10)
    event action: "approved", from: "pending", subject: spectrum, at: Time.utc(2026, 10, 24, 11)
    stats = described_class.new(type: "Spectrum")
    expect(stats.counts).to eq("approved" => 1)
    expect(stats.pending_wait).to eq(matched: 0, total: 1, median_seconds: nil)
  end

  it "retains the audit measurements when the original content is deleted" do
    event action: "submitted", at: Time.utc(2026, 10, 24, 10)
    event action: "approved", from: "pending", at: Time.utc(2026, 10, 24, 11)
    quest.destroy!
    expect(described_class.new.pending_wait).to eq(matched: 1, total: 1, median_seconds: 1.hour.to_f)
  end

  it "uses UTC days even when the connection and application time zones differ" do
    event action: "approved", from: "pending", at: Time.utc(2026, 10, 24, 0, 15)
    original_zone = ActiveRecord::Base.connection.select_value("SHOW TIME ZONE")
    ActiveRecord::Base.connection.execute("SET TIME ZONE 'America/New_York'")
    Time.use_zone("Pacific/Honolulu") do
      stats = described_class.new(from: "2026-10-24", through: "2026-10-24")
      expect(stats.daily).to eq(Date.new(2026, 10, 24) => 1)
    end
  ensure
    ActiveRecord::Base.connection.execute("SET TIME ZONE #{ActiveRecord::Base.connection.quote(original_zone)}") if original_zone
  end

  it "starts a shout-out's wait at its funded submission rather than its unfunded creation" do
    author = create :ace
    player = create :player
    post = author.shout_outs.create! target: player, target_name: player.name, draft_revision: 0,
      message: "A clear pass to the open teammate.", bid_cents: 100, payment_method: "credit", created_at: 2.days.ago
    expect(post.moderation_decisions).to be_empty
    buy_credit author
    post.reserve_credit!
    review_post post, action: "approve"
    stats = described_class.new(type: "ShoutOut")
    expect(stats.counts).to eq("approved" => 1)
    expect(stats.pending_wait).to eq(matched: 1, total: 1, median_seconds: 0.0)
  end

  it "bounds daily charts and rejects invalid filters" do
    expect(described_class.new(from: "2025-10-25", through: "2026-10-25").daily.size).to eq(366)
    [ { from: "2025-10-24" }, { from: "2026-10-26" }, { through: "2026-10-26" }, { from: "2026-02-30" }, { type: "Ace" }, { from: { day: "25" } } ].each do |filters|
      expect { described_class.new(**filters) }.to raise_error(ArgumentError)
    end
  end
end
