module ShoutOutPayments
  def paid_session(purchase, **changes)
    {
      "id" => "cs_test_#{purchase.id}", "mode" => "payment", "payment_status" => "paid", "currency" => "usd",
      "amount_total" => purchase.amount_cents, "client_reference_id" => "athleteace:#{purchase.id}",
      "metadata" => { "athleteace_purchase_id" => purchase.id.to_s, "ace_id" => purchase.ace_id.to_s },
      "payment_intent" => "pi_test_#{purchase.id}"
    }.merge(changes.transform_keys(&:to_s))
  end

  def buy_credit(ace, amount: 1000)
    purchase = ace.stripe_purchases.create!(amount_cents: amount, request_key: SecureRandom.uuid)
    purchase.fulfill!(paid_session(purchase))
    CreditAccount.for(ace)
  end

  def submit_credit(ace:, target:, message: "What a finish!", bid: 100)
    draft = ace.shout_out_drafts.create!(target: target, message: message)
    ShoutOutSubmission.call(draft: draft, revision: 0, bid_cents: bid, payment_method: "credit")
  end

  def review_post(post, action:, reviewer: create(:ace, moderator: true))
    Moderation::Review.call(record: post, actor: reviewer, action: action, revision: post.moderation_revision,
      status: post.moderation_status, reason: %w[reject hide].include?(action) ? "Not about the target" : nil)
  end
end

RSpec.configure { |config| config.include ShoutOutPayments }
