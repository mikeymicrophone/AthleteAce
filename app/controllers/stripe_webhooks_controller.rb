class StripeWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :require_ace_identity
  skip_before_action :reject_suspended_account

  def create
    return head :service_unavailable unless StripeCheckout.configured?
    event = Stripe::Webhook.construct_event(request.raw_post, request.headers["Stripe-Signature"], ENV.fetch("STRIPE_WEBHOOK_SECRET"))
    live = ENV.fetch("STRIPE_SECRET_KEY").start_with?("sk_live_", "rk_live_")
    return head :bad_request unless event.livemode == live
    session = event.data.object.to_hash.deep_stringify_keys
    purchase_id = session.dig("metadata", "athleteace_purchase_id")
    return head :ok unless purchase_id
    purchase = StripePurchase.find(purchase_id)
    case event.type
    when "checkout.session.completed"
      purchase.fulfill!(session) if session["payment_status"] == "paid"
    when "checkout.session.expired"
      purchase.with_lock do
        purchase.update!(status: "expired") if purchase.status == "pending" && purchase.stripe_session_id == session["id"]
      end
    end
    head :ok
  rescue Stripe::SignatureVerificationError, JSON::ParserError
    head :bad_request
  rescue ArgumentError, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound
    head :unprocessable_content
  end
end
