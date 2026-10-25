class Admin::ModerationOversightController < ApplicationController
  before_action :authenticate_ace!
  before_action :require_admin!
  before_action { response.headers["Cache-Control"] = "private, no-store" }

  def index
    @oversight = Admin::ModerationOversight.new(from: params[:from], through: params[:through], type: params[:item_type])
  rescue ArgumentError => error
    render plain: error.message, content_type: "text/plain", status: :bad_request
  end
end
