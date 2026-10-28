class AceProfilesController < ApplicationController
  before_action :authenticate_ace!

  def show
    return head :forbidden unless current_ace.can_moderate?

    response.headers["Cache-Control"] = "private, no-store"
    @ace = Ace.find params[:id]
    @tab = params[:tab].presence || "submissions"
    raise ActionController::BadRequest unless %w[submissions reports actions notes].include?(@tab)
    @own_profile = @ace.id == current_ace.id
    @escalation = ModerationEscalation.open.visible_to(current_ace).find_by(subject: @ace) unless @own_profile
    @can_manage = Moderation::PostingAction.allowed?(current_ace, @ace)
    @active_mute = @ace.active_posting_mute
    @warning_count = @ace.warnings.count
    @mute_count = @ace.mutes.count
    @submission_counts = Hash.new(0)
    Moderation::Queue::TYPES.values.each do |model|
      scope = model.where(created_by: @ace)
      scope = scope.where.not(funding_status: "unfunded") if model == ShoutOut
      scope.group(:moderation_status).count.each { |status, count| @submission_counts[status] += count }
    end
    reports = ShoutOutReport.where(shout_out: @ace.shout_outs)
    @report_count = reports.count unless @own_profile
    @open_report_count = reports.open.count unless @own_profile
    @reported_posts = @ace.shout_outs.live.where(id: ShoutOutReport.open.select(:shout_out_id)).order(:id).limit(100) if @can_manage
    if @tab == "reports" && !@own_profile
      @pagy, @reports = pagy(reports.includes(:reporter, :shout_out).order(created_at: :desc, id: :desc), limit: 25)
    elsif @tab == "actions"
      @warnings_pagy, @warnings = pagy(@ace.warnings.includes(:moderator).order(created_at: :desc, id: :desc), limit: 25, page_key: "warnings_page")
      @mutes_pagy, @mutes = pagy(@ace.mutes.includes(:moderator, :ended_by).order(created_at: :desc, id: :desc), limit: 25, page_key: "mutes_page")
    elsif @tab == "notes" && !@own_profile
      @pagy, @notes = pagy(@ace.moderator_notes.includes(:moderator).order(created_at: :desc, id: :desc), limit: 25)
    end
    @submissions = Moderation::Queue::TYPES.values.flat_map do |model|
      scope = model.where(created_by: @ace)
      scope = scope.where.not(funding_status: "unfunded") if model == ShoutOut
      scope.order(created_at: :desc, id: :desc).limit(10).to_a
    end.sort_by { |record| [ record.created_at, record.id ] }.reverse.first(10)
  end
end
