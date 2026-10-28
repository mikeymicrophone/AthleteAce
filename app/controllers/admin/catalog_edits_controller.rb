class Admin::CatalogEditsController < ApplicationController
  before_action :authenticate_ace!
  before_action :require_admin!
  before_action { response.headers["Cache-Control"] = "private, no-store" }

  def index
    raise ArgumentError, "Invalid reason filter." unless params[:pending].nil? || %w[0 1].include?(params[:pending])
    @pending = params[:pending] == "1"
    records = CatalogEdit.all
    records = records.where(reason: nil) if @pending
    @pagy, @edits = pagy(records.order(id: :desc), limit: 25)
  rescue ArgumentError => error
    render plain: error.message, status: :bad_request
  end

  def show
    @edit = CatalogEdit.find(params[:id])
  end

  def update
    @edit = CatalogEdit.find(params[:id])
    @edit.supply_reason!(actor: current_ace, reason: params[:reason])
    redirect_to admin_catalog_edit_path(@edit), status: :see_other, notice: "Reason saved."
  rescue Admin::EditCatalog::Forbidden => error
    render plain: error.message, status: :forbidden
  rescue Admin::EditCatalog::Conflict => error
    @error = error.message
    render :show, status: :conflict
  rescue ArgumentError, ActiveRecord::RecordInvalid => error
    @error = error.message
    render :show, status: :unprocessable_content
  end
end
