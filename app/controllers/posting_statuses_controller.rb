class PostingStatusesController < ApplicationController
  before_action :authenticate_ace!
  before_action { response.headers["Cache-Control"] = "private, no-store" }

  def show
    @posting_mute = current_ace.active_posting_mute
    @warnings_pagy, @warnings = pagy(current_ace.warnings.order(created_at: :desc, id: :desc), limit: 25, page_key: "warnings_page")
    @mutes_pagy, @mutes = pagy(current_ace.mutes.order(created_at: :desc, id: :desc), limit: 25, page_key: "mutes_page")
  end
end
