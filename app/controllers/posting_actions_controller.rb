class PostingActionsController < ApplicationController
  before_action :authenticate_ace!
  before_action { response.headers["Cache-Control"] = "private, no-store" }

  def create
    ace = Ace.find(params[:ace_profile_id])
    Moderation::PostingAction.call(ace: ace, actor: current_ace, kind: params[:kind],
      attributes: params.require(:posting_action).permit(:reason, :related_item, :duration_hours, :note, :hide_post_id, :body, :request_key, :mute_id).to_h.symbolize_keys)
    redirect_to ace_profile_path(ace, tab: params[:kind] == "note" ? "notes" : "actions"), status: :see_other, notice: "Posting moderation action recorded."
  rescue Moderation::Review::Forbidden => error
    render plain: error.message, status: :forbidden
  rescue Moderation::Review::Conflict => error
    render plain: error.message, status: :conflict
  rescue ArgumentError, ActiveRecord::RecordInvalid => error
    render plain: error.message, status: :unprocessable_content
  end
end
