require "rails_helper"

RSpec.describe "Shout-out credit accounting" do
  let(:ace) { create(:ace) }
  let(:target) { create(:player) }

  it "credits the full outlay once and cannot replay a purchase with different payment details" do
    purchase = ace.stripe_purchases.create!(amount_cents: 1000, request_key: SecureRandom.uuid)
    2.times { purchase.fulfill!(paid_session(purchase)) }
    account = CreditAccount.for(ace)
    expect(account.available_cents).to eq(1000)
    expect(account.credit_entries.count).to eq(1)
    expect { purchase.fulfill!(paid_session(purchase, amount_total: 999)) }.to raise_error(ArgumentError)
    expect(account.reload.available_cents).to eq(1000)
  end

  it "atomically reserves credit, spends it on approval, and returns the full bid on removal" do
    account = buy_credit(ace)
    post = submit_credit(ace: ace, target: target, bid: 325)
    expect(account.reload.attributes.values_at("available_cents", "reserved_cents")).to eq([ 675, 325 ])
    review_post(post, action: "approve")
    expect(post.reload.funding_status).to eq("spent")
    expect(account.reload.attributes.values_at("available_cents", "reserved_cents")).to eq([ 675, 0 ])
    review_post(post, action: "hide")
    expect(account.reload.attributes.values_at("available_cents", "reserved_cents")).to eq([ 1000, 0 ])
    expect { review_post(post, action: "hide") }.to raise_error(Moderation::Review::Conflict)
    expect { review_post(post, action: "reopen") }.to raise_error(Moderation::Review::Conflict)
    expect(account.reload.available_cents).to eq(1000)
    expect(post.moderation_decisions.pluck(:action)).to eq(%w[submitted approved hidden])
  end

  it "releases rejected reservations, and lets credit bids start at one cent" do
    account = buy_credit(ace)
    post = submit_credit(ace: ace, target: target, bid: 1)
    expect(account.reload.reserved_cents).to eq(1)
    review_post(post, action: "reject")
    expect(account.reload.attributes.values_at("available_cents", "reserved_cents")).to eq([ 1000, 0 ])
  end

  it "rolls back insufficient credit and deduplicates the same saved draft submission" do
    draft = ace.shout_out_drafts.create!(target: target, message: "Great finish")
    expect {
      ShoutOutSubmission.call(draft: draft, revision: 0, bid_cents: 50, payment_method: "credit")
    }.to raise_error(ArgumentError, /not enough/)
    expect(ShoutOut.count).to eq(0)
    buy_credit(ace)
    first = ShoutOutSubmission.call(draft: draft, revision: 0, bid_cents: 50, payment_method: "credit")
    second = ShoutOutSubmission.call(draft: draft, revision: 0, bid_cents: 50, payment_method: "credit")
    expect(first.id).to eq(second.id)
    expect(CreditAccount.for(ace).reserved_cents).to eq(50)
    expect { ShoutOutSubmission.call(draft: draft, revision: 0, bid_cents: 51, payment_method: "credit") }.to raise_error(ArgumentError, /already submitted/)
  end

  it "rolls back an insufficient reservation even when its caller rescues inside a transaction" do
    draft = ace.shout_out_drafts.create!(target: target, message: "Great finish")
    ShoutOut.transaction do
      expect { ShoutOutSubmission.call(draft: draft, revision: 0, bid_cents: 50, payment_method: "credit") }.to raise_error(ArgumentError)
      expect(ShoutOut.where(shout_out_draft: draft)).to be_empty
    end
  end

  it "keeps direct payments unreviewable until confirmed, and refunds them as credit" do
    draft = ace.shout_out_drafts.create!(target: target, message: "Great finish")
    post = ShoutOutSubmission.call(draft: draft, revision: 0, bid_cents: 75, payment_method: "stripe")
    reviewer = create(:ace, moderator: true)
    expect(Moderation::Queue.new(reviewer: reviewer).items).not_to include(post)
    expect(post.moderation_decisions).to be_empty
    expect { review_post(post, action: "approve", reviewer: reviewer) }.to raise_error(Moderation::Review::Conflict)
    purchase = post.stripe_purchases.create!(ace: ace, amount_cents: 75, request_key: SecureRandom.uuid)
    purchase.fulfill!(paid_session(purchase))
    expect(Moderation::Queue.new(reviewer: reviewer).items).to include(post)
    account = CreditAccount.for(ace)
    expect(account.attributes.values_at("available_cents", "reserved_cents")).to eq([ 0, 75 ])
    review_post(post.reload, action: "approve", reviewer: reviewer)
    review_post(post, action: "hide", reviewer: reviewer)
    expect(account.reload.attributes.values_at("available_cents", "reserved_cents")).to eq([ 75, 0 ])
  end

  it "cannot self-review, alter funded text, or approve a deleted target" do
    ace.update!(admin: true)
    account = buy_credit(ace)
    post = submit_credit(ace: ace, target: target)
    expect { review_post(post, action: "approve", reviewer: ace) }.to raise_error(Moderation::Review::Forbidden)
    expect { post.update!(message: "Changed message") }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    target.destroy!
    post.reload
    expect { review_post(post, action: "approve") }.to raise_error(Moderation::Review::Conflict)
    review_post(post, action: "reject")
    expect(account.reload.available_cents).to eq(1000)
  end

  it "parses exact cents and enforces the direct payment minimum" do
    expect(UsdAmount.parse("0.01")).to eq(1)
    expect(UsdAmount.parse("12.34")).to eq(1234)
    %w[-1 0 1.001 NaN Infinity 1e3].each { |text| expect { UsdAmount.parse(text) }.to raise_error(ArgumentError) }
    draft = ace.shout_out_drafts.create!(target: target, message: "Great finish")
    expect { ShoutOutSubmission.call(draft: draft, revision: 0, bid_cents: 49, payment_method: "stripe") }.to raise_error(ArgumentError)
  end
end
