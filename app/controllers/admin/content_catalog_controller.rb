class Admin::ContentCatalogController < ApplicationController
  before_action :authenticate_ace!
  before_action :require_admin!
  before_action { response.headers["Cache-Control"] = "private, no-store" }

  def index
    @directory = Admin::ContentDirectory.new(params)
    @counts = Admin::ContentDirectory::TYPES.transform_values(&:count)
    @creators = @directory.creators
    @pagy, rows = pagy(@directory.records, limit: 25)
    @records = @directory.load_records(rows)
    @escalations = ModerationEscalation.open.visible_to(current_ace)
      .where(subject_type: Admin::ContentDirectory::TYPES.keys, subject_id: @records.map(&:id))
      .index_by { |escalation| [ escalation.subject_type, escalation.subject_id ] }
  rescue ArgumentError => error
    render plain: error.message, content_type: "text/plain", status: :bad_request
  end
end
