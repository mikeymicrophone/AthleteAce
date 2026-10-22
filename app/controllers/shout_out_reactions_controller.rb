class ShoutOutReactionsController < ApplicationController
  before_action :authenticate_ace!
  before_action { response.headers["Cache-Control"] = "private, no-store" }

  def update
    change_reaction(present: true)
  end

  def destroy
    change_reaction(present: false)
  end

  private

  def change_reaction(present:)
    kind = params.expect(:kind)
    raise ActionController::BadRequest unless ShoutOutReaction::KINDS.key?(kind)
    post = ShoutOut.find(params[:shout_out_id])
    post.with_lock do
      raise ActiveRecord::RecordNotFound unless post.approved? && post.funding_status == "spent"
      reactions = post.shout_out_reactions.where(ace: current_ace, kind: kind)
      present ? reactions.first_or_create! : reactions.destroy_all
    end
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(post, partial: "shout_outs/card", locals: { post: post }) }
      format.html { redirect_back fallback_location: feed_post_path(post), allow_other_host: false, status: :see_other }
    end
  end
end
