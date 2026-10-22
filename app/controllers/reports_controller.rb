class ReportsController < ApplicationController
  before_action :authenticate_ace!
  before_action :require_reviewer
  before_action { response.headers["Cache-Control"] = "private, no-store" }

  def index
    @status = params[:status].presence || "open"
    raise ActionController::BadRequest unless %w[open resolved].include?(@status)
    reports = ShoutOutReport.joins(:shout_out).where.not(shout_outs: { created_by_id: current_ace.id })
    @open_count = reports.open.distinct.count(:shout_out_id)
    @resolved_count = reports.where(resolved_at: Time.current.beginning_of_week..).distinct.count(:shout_out_id)
    reports = @status == "open" ? reports.open : reports.where.not(resolved_at: nil)
    posts = ShoutOut.where(id: reports.select(:shout_out_id)).includes(:created_by)
      .joins(:shout_out_reports).merge(reports.except(:joins))
      .group("shout_outs.id").select("shout_outs.*, COUNT(shout_out_reports.id) AS report_count, MIN(shout_out_reports.created_at) AS first_reported_at")
      .order(Arel.sql("COUNT(shout_out_reports.id) DESC, MIN(shout_out_reports.created_at) ASC"), id: :asc)
    @pagy, @posts = pagy(posts, limit: 25)
  end

  def show
    @post = ShoutOut.where.not(created_by_id: current_ace.id).find(params[:id])
    raise ActiveRecord::RecordNotFound unless @post.shout_out_reports.exists?
    @open_reports = @post.shout_out_reports.open
    @last_report_id = @open_reports.maximum(:id)
    @own_report = @open_reports.where(reporter_id: current_ace.id).exists?
    @reason_counts = @open_reports.group(:reason).count
    @pagy, @reports = pagy(@post.shout_out_reports.includes(:reporter, :resolved_by).order(created_at: :desc, id: :desc), limit: 25)
  end

  def update
    post = ShoutOut.find(params[:id])
    Moderation::ResolveReports.call(post: post, actor: current_ace, action: params.expect(:decision),
      revision: Integer(params.expect(:revision).to_s, 10), last_report_id: Integer(params.expect(:last_report_id).to_s, 10), reason: params[:reason].to_s)
    redirect_to report_path(post), status: :see_other, notice: "Reports resolved."
  rescue Moderation::Review::Forbidden => error
    render plain: error.message, status: :forbidden
  rescue Moderation::Review::Conflict => error
    render plain: error.message, status: :conflict
  rescue ArgumentError => error
    render plain: error.message, status: :unprocessable_content
  end

  private

  def require_reviewer
    head :forbidden unless current_ace.can_moderate?
  end
end
