require "rails_helper"

RSpec.describe "Quest approval attribution", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:author) { create :ace }
  let(:reviewer) { create :ace, moderator: true }

  def approve(quest)
    Moderation::Review.call(record: quest, actor: reviewer, action: "approve", revision: quest.moderation_revision, status: quest.moderation_status)
  end

  it "shows the actual approval event in UTC rather than quest creation time" do
    quest = nil
    travel_to(Time.utc(2026, 10, 20, 12)) { quest = create :quest, created_by: author }
    travel_to(Time.utc(2026, 10, 22, 0, 30)) { approve quest }
    get quest_path(quest)
    expect(response).to have_http_status(:ok)
    expect(Nokogiri::HTML(response.body).at_css(".quest-approval time")["datetime"]).to eq("2026-10-22T00:30:00Z")
    expect(response.body).to include("Approved", "October 22, 2026", "UTC")
  end

  it "does not reuse an older revision's date after an edit and reapproval" do
    quest = create :quest, created_by: author
    travel_to(Time.utc(2026, 10, 20, 12)) { approve quest }
    quest.update! description: "A revised roster challenge"
    sign_in author
    get quest_path(quest)
    expect(Nokogiri::HTML(response.body).at_css(".quest-approval")).to be_nil
    travel_to(Time.utc(2026, 10, 23, 18)) { approve quest }
    get quest_path(quest)
    expect(Nokogiri::HTML(response.body).at_css(".quest-approval time")["datetime"]).to eq("2026-10-23T18:00:00Z")
  end

  it "does not invent a date for legacy approved content without an approval event" do
    quest = create :quest
    ModerationDecision.where(subject: quest).delete_all
    get quest_path(quest)
    expect(response.body).to include("Approval date not recorded.")
    expect(Nokogiri::HTML(response.body).at_css(".quest-approval time")).to be_nil
  end

  it "uses a recorded trusted approval when present and also renders it in discovery" do
    quest = create :quest
    expected = quest.moderation_decisions.where(action: "approved").sole.created_at.utc.iso8601
    sign_in author
    get random_quests_path
    expect(response.body).to include(quest.name, "Quest Discovery")
    expect(Nokogiri::HTML(response.body).at_css(".quest-approval time")["datetime"]).to eq(expected)
  end
end
