class StripeCheckout
  def self.configured?
    ENV["STRIPE_SECRET_KEY"].present? && ENV["STRIPE_WEBHOOK_SECRET"].present?
  end

  def self.call(purchase:, return_url:)
    raise ArgumentError, "Stripe payments are not configured yet." unless configured?
    raise ArgumentError, "This purchase is no longer awaiting payment." unless purchase.status == "pending"
    client = Stripe::StripeClient.new(ENV.fetch("STRIPE_SECRET_KEY"))
    if purchase.stripe_session_id
      session = client.v1.checkout.sessions.retrieve(purchase.stripe_session_id)
      purchase.update!(status: "expired") if session.status == "expired"
      return session.status == "open" ? session.url : return_url
    end
    session = client.v1.checkout.sessions.create({
      mode: "payment", payment_method_types: [ "card" ], client_reference_id: "athleteace:#{purchase.id}",
      metadata: { athleteace_purchase_id: purchase.id, ace_id: purchase.ace_id },
      line_items: [ { quantity: 1, price_data: { currency: "usd", unit_amount: purchase.amount_cents,
        product_data: { name: purchase.shout_out ? "Shout-out for #{purchase.shout_out.target_name}" : "AthleteAce credit" } } } ],
      success_url: return_url, cancel_url: return_url
    }, { idempotency_key: "athleteace-purchase-#{purchase.id}" })
    purchase.update!(stripe_session_id: session.id)
    session.url
  end
end
