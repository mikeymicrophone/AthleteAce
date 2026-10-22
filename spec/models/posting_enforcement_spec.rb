require "rails_helper"

RSpec.describe "Posting access enforcement" do
  let(:ace) { create(:ace) }
  let(:reviewer) { create(:ace, moderator: true) }

  def mute
    Moderation::PostingAction.call(ace: ace, actor: reviewer, kind: "mute", attributes: {
      request_key: SecureRandom.uuid, reason: "Keep posts about sports", duration_hours: "24" })
  end

  it "enforces a mute at creation even when controller checks are bypassed" do
    buy_credit(ace)
    target = create(:player)
    draft = ace.shout_out_drafts.create!(target: target, message: "A remarkable effort")
    quest = create(:quest)
    achievement = create(:achievement)
    mute
    [ -> { create(:quest, created_by: ace) }, -> { create(:achievement, created_by: ace) },
      -> { create(:spectrum, created_by: ace) }, -> { create(:highlight, quest: quest, achievement: achievement, created_by: ace) },
      -> { ShoutOutSubmission.call(draft: draft, revision: 0, bid_cents: 100, payment_method: "credit") } ].each do |operation|
      expect { operation.call }.to raise_error(Ace::PostingMuted)
    end
    expect(ace.shout_outs.count).to eq(0)
    expect(CreditAccount.for(ace).available_cents).to eq(1000)
    expect(CreditAccount.for(ace).reserved_cents).to eq(0)
    expect(ModerationDecision.where(actor: ace).count).to eq(0)
  end

  it "honors in-flight payments and reviews for submissions made before the mute" do
    draft = ace.shout_out_drafts.create!(target: create(:team), message: "A game to remember")
    post = ShoutOutSubmission.call(draft: draft, revision: 0, bid_cents: 125, payment_method: "stripe")
    purchase = post.stripe_purchases.create!(ace: ace, amount_cents: 125, request_key: SecureRandom.uuid)
    mute
    purchase.fulfill!(paid_session(purchase))
    expect(post.reload.funding_status).to eq("reserved")
    review_post(post, action: "approve", reviewer: reviewer)
    expect(post.reload.moderation_status).to eq("approved")
    expect(CreditAccount.for(ace).reserved_cents).to eq(0)
    expect(ace.active_posting_mute).to be_present
  end

  it "retains warning and note records and their subject snapshot after related content or reviewers disappear" do
    quest = create(:quest, created_by: ace, name: "Know the starting quarterbacks")
    warning = Moderation::PostingAction.call(ace: ace, actor: reviewer, kind: "warn", attributes: {
      request_key: SecureRandom.uuid, reason: "Clarify the scope", related_item: "Quest:#{quest.id}" })
    note = Moderation::PostingAction.call(ace: ace, actor: reviewer, kind: "note", attributes: { request_key: SecureRandom.uuid, body: "Internal review context" })
    expect { warning.update!(reason: "Rewrite") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { note.update!(body: "Rewrite") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    quest.destroy!
    reviewer.destroy!
    expect(warning.reload.subject_name).to eq("Know the starting quarterbacks")
    expect(warning.moderator).to be_nil
    expect(note.reload.body).to eq("Internal review context")
  end
end
