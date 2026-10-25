class Admin::CatalogRecordsController < ApplicationController
  before_action :authenticate_ace!
  before_action :require_admin!
  before_action { response.headers["Cache-Control"] = "private, no-store" }
  before_action :load_record, only: [ :edit, :update ]

  def index
    @directory = Admin::SportsDirectory.new(params)
    respond_to do |format|
      format.html do
        @counts = { players: Player.count, teams: Team.count }
        @leagues = League.order(:name)
        @teams = Team.order(:territory, :mascot)
        @pagy, @records = pagy(@directory.records, limit: 25)
        @number_assignments = @directory.number_assignments(@records)
        @edited_ids = @directory.edited_records.where(id: @records.map(&:id)).pluck(:id)
      end
      format.csv do
        send_data @directory.csv, type: "text/csv; charset=utf-8", filename: "athleteace-#{@directory.kind}-#{Date.current.iso8601}.csv"
      end
    end
  rescue ArgumentError => error
    render plain: error.message, content_type: "text/plain", status: :bad_request
  end

  def new
    prepare_new_player
    @values = Player.new.attributes
    @request_key = SecureRandom.uuid
  end

  def create
    prepare_new_player
    @values = params.expect(record: @fields).to_h
    @request_key = params.expect(:request_key)
    edit = Admin::EditCatalog.create_player(actor: current_ace, attributes: @values, entity_code: params[:entity_code],
      sport_id: params[:sport_id], request_key: @request_key)
    redirect_to admin_catalog_edit_path(edit), status: :see_other, notice: "Player created. Why did you make this change?"
  rescue Admin::EditCatalog::Forbidden => error
    render plain: error.message, status: :forbidden
  rescue Admin::EditCatalog::Conflict => error
    @error = error.message
    render :new, status: :conflict
  rescue ArgumentError, ActiveRecord::RecordInvalid => error
    @error = error.message
    render :new, status: :unprocessable_content
  end

  def edit
    @values = @record.attributes
    @version = Admin::EditCatalog.version(@record)
    @request_key = SecureRandom.uuid
  end

  def update
    @version = params.expect(:version)
    @request_key = params.expect(:request_key)
    @values = params.expect(record: @fields).to_h
    edit = Admin::EditCatalog.call(record: @record, actor: current_ace, attributes: @values, version: @version, request_key: @request_key)
    if edit
      redirect_to admin_catalog_edit_path(edit), status: :see_other, notice: "Saved. Why did you make this change?"
    else
      redirect_to edit_admin_catalog_record_path(@record, kind: @kind), status: :see_other, notice: "No changes to save."
    end
  rescue Admin::EditCatalog::Forbidden => error
    render plain: error.message, status: :forbidden
  rescue Admin::EditCatalog::Conflict => error
    @error = error.message
    render :edit, status: :conflict
  rescue ArgumentError, ActiveRecord::RecordInvalid => error
    @error = error.message
    render :edit, status: :unprocessable_content
  end

  private

  def prepare_new_player
    raise ActiveRecord::RecordNotFound unless params[:kind].blank? || params[:kind] == "players"
    @fields = Admin::EditCatalog::FIELDS.fetch("Player")
    @sports = Sport.order(:name, :id)
  end

  def load_record
    @kind = params[:kind].presence || "players"
    @record = Admin::EditCatalog.model_for(@kind).find(params[:id])
    @fields = Admin::EditCatalog::FIELDS.fetch(@record.class.name)
    identity = @record.entity_code.present? ? { entity_code: @record.entity_code } : { entity_code: nil, record_id: @record.id }
    @history = CatalogEdit.where(record_type: @record.class.name, **identity).order(id: :desc).limit(10)
  end
end
