class StripePurchase < ApplicationRecord
  belongs_to :ace
  belongs_to :shout_out, optional: true
  validates :amount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 50, less_than_or_equal_to: 99_999_999 }
  validates :request_key, presence: true

  def fulfill!(session)
    with_lock(requires_new: true) do
      unless session["mode"] == "payment" && session["payment_status"] == "paid" && session["currency"] == "usd" &&
          session["amount_total"] == amount_cents && session["client_reference_id"] == "athleteace:#{id}" &&
          session.dig("metadata", "ace_id") == ace_id.to_s && session["payment_intent"].present? &&
          (stripe_session_id.nil? || stripe_session_id == session["id"])
        raise ArgumentError, "The Stripe payment does not match this purchase."
      end
      return if status == "paid"
      account = CreditAccount.for(ace)
      if shout_out
        shout_out.with_lock do
          raise ArgumentError, "The post owner does not match the purchaser." unless shout_out.created_by_id == ace_id && shout_out.bid_cents == amount_cents
          account.apply!(source: self, kind: "purchase", available_delta: amount_cents)
          shout_out.reserve_credit!
        end
      else
        account.apply!(source: self, kind: "purchase", available_delta: amount_cents)
      end
      update!(status: "paid", stripe_session_id: session.fetch("id"), stripe_payment_intent_id: session.fetch("payment_intent"))
    end
  end
end
