require "rails_helper"

RSpec.describe "Content moderation" do
  let(:author) { create(:ace) }
  let(:reviewer) { create(:ace, moderator: true) }

  it "holds fan content, trusts catalog and admin creation, and records initial decisions" do
    [ create(:quest, created_by: author), create(:achievement, created_by: author),
      create(:spectrum, created_by: author) ].each do |item|
      expect(item.moderation_status).to eq("pending")
      expect(item.moderation_decisions.first.action).to eq("submitted")
    end
    expect(create(:quest).moderation_status).to eq("approved")
    expect(create(:quest, created_by: create(:ace, :admin)).moderation_status).to eq("approved")
  end

  it "rejects self-review and stale decisions and records overrides without rewriting history" do
    item = create(:quest, created_by: reviewer)
    expect {
      Moderation::Review.call(record: item, actor: reviewer, action: "approve", revision: 1, status: "pending")
    }.to raise_error(Moderation::Review::Forbidden)
    admin = create(:ace, :admin)
    Moderation::Review.call(record: item, actor: admin, action: "reject", revision: 1, status: "pending", reason: "Unclear target")
    expect {
      Moderation::Review.call(record: item, actor: admin, action: "approve", revision: 1, status: "pending")
    }.to raise_error(Moderation::Review::Conflict)
    Moderation::Review.call(record: item, actor: admin, action: "reopen", revision: 1, status: "rejected", reason: "New evidence")
    Moderation::Review.call(record: item, actor: admin, action: "approve", revision: 1, status: "pending")
    expect(item.moderation_decisions.order(:id).pluck(:action)).to eq(%w[submitted rejected reopened approved])
    expect { item.moderation_decisions.first.update!(reason: "Rewritten") }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it "invalidates approval after an edit and keeps the previous content snapshot" do
    item = create(:quest, created_by: author, name: "Original")
    Moderation::Review.call(record: item, actor: reviewer, action: "approve", revision: 1, status: "pending")
    item.moderation_editor = create(:ace, :admin)
    item.update!(name: "Changed")
    expect(item.moderation_revision).to eq(2)
    expect(item.moderation_status).to eq("pending")
    expect(item.moderation_decisions.where(action: "approved").first.snapshot["name"]).to eq("Original")
    expect(item.moderation_decisions.order(:id).last.actor).to eq(item.moderation_editor)
  end

  it "rejects concurrent stale edits instead of reusing a content revision" do
    original = create(:quest, created_by: author)
    stale = Quest.find(original.id)
    original.update!(name: "First edit")
    expect { stale.update!(name: "Overlapping edit") }.to raise_error(ActiveRecord::StaleObjectError)
    expect(original.reload.moderation_revision).to eq(2)
  end

  it "preserves an explicit imported rejection instead of publishing restored content" do
    restored = create(:quest, moderation_status: "rejected")
    expect(restored.reload.moderation_status).to eq("rejected")
    expect(restored.moderation_decisions.first.action).to eq("rejected")
  end

  it "prevents a pending highlight or achievement from changing public goal requirements" do
    quest = create(:quest)
    goal = create(:goal, quest: quest, progress: 1)
    create(:highlight, quest: quest)
    pending = create(:highlight, quest: quest, created_by: author)
    create(:highlight, quest: quest, achievement: create(:achievement, created_by: author))
    expect(goal.required_achievements.count).to eq(1)
    expect(goal.percent_complete).to eq(100)
    expect(quest.required_achievements).not_to include(pending.achievement)
  end
end
