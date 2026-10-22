class WalletsController < ApplicationController
  before_action :authenticate_ace!
  before_action { response.headers["Cache-Control"] = "private, no-store" }

  def show
    @account = CreditAccount.for(current_ace)
    @pagy, @entries = pagy(@account.credit_entries.order(created_at: :desc, id: :desc))
  end

  def create
    amount = UsdAmount.parse(params[:amount], minimum_cents: 50)
    key = params.expect(:request_key).to_s
    raise ArgumentError, "Open your wallet again to start a new purchase." unless key.match?(/\A[0-9a-f-]{36}\z/)
    purchase = current_ace.stripe_purchases.find_or_create_by!(request_key: key) do |record|
      record.amount_cents = amount
    end
    unless purchase.amount_cents == amount && !purchase.shout_out_id
      raise ArgumentError, "This purchase was already started for a different amount."
    end
    return redirect_to stripe_purchase_path(purchase), status: :see_other unless purchase.status == "pending"
    redirect_to StripeCheckout.call(purchase: purchase, return_url: stripe_purchase_url(purchase)), allow_other_host: true, status: :see_other
  rescue ArgumentError, ActiveRecord::RecordInvalid, Stripe::StripeError => error
    redirect_to wallet_path, status: :see_other, alert: error.is_a?(Stripe::StripeError) ? "Stripe checkout could not be opened. Try again." : error.message
  end
end
