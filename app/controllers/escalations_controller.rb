class EscalationsController < ApplicationController
  before_action :authenticate_ace!
  before_action :require_reviewer
  before_action { response.headers["Cache-Control"] = "private, no-store" }

  def index
    @status = params[:status].presence || "open"
    raise ActionController::BadRequest unless %w[open resolved].include?(@status)
    visible = ModerationEscalation.visible_to(current_ace)
    @open_count = visible.open.count
    cases = @status == "open" ? visible.open.order(:created_at, :id) : visible.where.not(resolved_at: nil).order(resolved_at: :desc, id: :desc)
    @pagy, @escalations = pagy(cases.includes(:requested_by, :resolved_by), limit: 25)
  end

  def create
    model = { **Moderation::Queue::TYPES, "Ace" => Ace }[params[:subject_type]] || raise(ActiveRecord::RecordNotFound)
    subject = model.find(params.expect(:subject_id))
    escalation = Moderation::Escalate.call(subject: subject, actor: current_ace, reason: params[:reason],
      request_key: params.expect(:request_key), revision: params[:revision].present? ? Integer(params[:revision].to_s, 10) : nil, status: params[:captured_status])
    redirect_to escalation_path(escalation), status: :see_other, notice: "Escalated to admin."
  rescue Moderation::Review::Forbidden => error
    render plain: error.message, status: :forbidden
  rescue Moderation::Review::Conflict => error
    render plain: error.message, status: :conflict
  rescue ArgumentError, ActiveRecord::RecordInvalid => error
    render plain: error.message, status: :unprocessable_content
  end

  def show
    @escalation = ModerationEscalation.visible_to(current_ace).includes(:requested_by, :resolved_by).find(params[:id])
    @subject = @escalation.subject
    @own_report = @subject.is_a?(ShoutOut) && @subject.shout_out_reports.open.where(reporter_id: current_ace.id).exists?
    @can_resolve = current_ace.admin? && @escalation.requested_by_id != current_ace.id && !@own_report && !@escalation.resolved_at?
    @resolutions = { "no_change" => ModerationEscalation::RESOLUTIONS.fetch("no_change") }
    if @escalation.current_content?
      actions = case @subject.moderation_status
      when "pending" then %w[approve reject]
      when "approved" then %w[hide]
      else @subject.is_a?(ShoutOut) && @subject.funding_status == "refunded" ? [] : %w[reopen]
      end
      @resolutions.merge!(ModerationEscalation::RESOLUTIONS.slice(*actions))
    end
  end

  def update
    escalation = ModerationEscalation.visible_to(current_ace).find(params[:id])
    Moderation::ResolveEscalation.call(escalation: escalation, actor: current_ace, resolution: params[:resolution],
      reason: params[:reason], version: Integer(params.expect(:version).to_s, 10))
    redirect_to escalation_path(escalation), status: :see_other, notice: "Escalation resolved."
  rescue Moderation::Review::Forbidden => error
    render plain: error.message, status: :forbidden
  rescue Moderation::Review::Conflict => error
    render plain: error.message, status: :conflict
  rescue ArgumentError, ActiveRecord::RecordInvalid => error
    render plain: error.message, status: :unprocessable_content
  end

  private

  def require_reviewer
    head :forbidden unless current_ace.can_moderate?
  end
end
