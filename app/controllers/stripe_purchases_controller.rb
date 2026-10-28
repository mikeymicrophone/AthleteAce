class StripePurchasesController < ApplicationController
  before_action :authenticate_ace!
  before_action { response.headers["Cache-Control"] = "private, no-store" }

  def show
    @purchase = current_ace.stripe_purchases.find(params[:id])
  end

  def pay
    purchase = current_ace.stripe_purchases.find(params[:id])
    return redirect_to stripe_purchase_path(purchase), status: :see_other if purchase.status == "paid"
    redirect_to StripeCheckout.call(purchase: purchase, return_url: stripe_purchase_url(purchase)), allow_other_host: true, status: :see_other
  rescue ArgumentError, Stripe::StripeError => error
    redirect_to stripe_purchase_path(purchase), status: :see_other, alert: error.is_a?(Stripe::StripeError) ? "Stripe checkout could not be opened. Try again." : error.message
  end
end
