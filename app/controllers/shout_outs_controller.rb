class ShoutOutsController < ApplicationController
  before_action :authenticate_ace!
  before_action :require_posting_access!, only: %i[create copy_to_draft]
  before_action { response.headers["Cache-Control"] = "private, no-store" }

  HISTORY_FILTERS = {
    "all" => { label: "All", conditions: {} },
    "awaiting_payment" => { label: "Awaiting payment", conditions: { funding_status: "unfunded" } },
    "in_review" => { label: "In review", conditions: { moderation_status: "pending", funding_status: "reserved" } },
    "live" => { label: "Live", conditions: { moderation_status: "approved", funding_status: "spent" } },
    "rejected" => { label: "Rejected", conditions: { moderation_status: "rejected" } },
    "hidden" => { label: "Hidden", conditions: { moderation_status: "hidden" } }
  }.freeze

  def index
    @status = params[:status].presence || "all"
    return head :bad_request unless HISTORY_FILTERS.key?(@status)

    posts = current_ace.shout_outs
    @filters = HISTORY_FILTERS
    @counts = @filters.transform_values { |filter| posts.where(filter.fetch(:conditions)).count }
    @bid_totals = posts.group(:funding_status).sum(:bid_cents)
    @pagy, @shout_outs = pagy(posts.where(@filters.fetch(@status).fetch(:conditions)).order(created_at: :desc, id: :desc))
  end

  def show
    @shout_out = current_ace.shout_outs.find(params[:id])
  end

  def copy_to_draft
    post = current_ace.shout_outs.find(params[:id])
    draft = current_ace.shout_out_drafts.create!(target: post.target, message: post.message)
    redirect_to edit_shout_out_draft_path(draft), status: :see_other,
      notice: "Copied to a new private draft. The original submission and its credit are unchanged."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to shout_out_path(post), status: :see_other, alert: error.record.errors.full_messages.to_sentence
  end

  def create
    draft = current_ace.shout_out_drafts.find(params.expect(:draft_id))
    post = ShoutOutSubmission.call(draft: draft, revision: Integer(params.expect(:draft_revision).to_s, 10),
      bid_cents: UsdAmount.parse(params[:bid]), payment_method: params[:payment_method])
    redirect_to shout_out_path(post), status: :see_other
  rescue ArgumentError, ActiveRecord::RecordInvalid => error
    redirect_to edit_shout_out_draft_path(draft), status: :see_other, alert: error.message
  end

  def pay
    post = current_ace.shout_outs.find(params[:id])
    purchase = post.with_lock do
      raise ArgumentError, "This post is already funded." unless post.funding_status == "unfunded" && post.payment_method == "stripe"
      post.stripe_purchases.where(status: "pending").first || post.stripe_purchases.create!(ace: current_ace,
        amount_cents: post.bid_cents, request_key: SecureRandom.uuid)
    end
    redirect_to StripeCheckout.call(purchase: purchase, return_url: stripe_purchase_url(purchase)), allow_other_host: true, status: :see_other
  rescue ArgumentError, Stripe::StripeError => error
    redirect_to shout_out_path(post), status: :see_other, alert: error.is_a?(Stripe::StripeError) ? "Stripe checkout could not be opened. Try again." : error.message
  end
end
