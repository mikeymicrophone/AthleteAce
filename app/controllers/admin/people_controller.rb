class Admin::PeopleController < ApplicationController
  before_action :authenticate_ace!
  before_action :require_admin!
  before_action { response.headers["Cache-Control"] = "private, no-store" }

  def index
    @directory = Admin::PeopleDirectory.new(params)
    @counts = { "aces" => Ace.count, "admins" => Ace.where(admin: true).count,
      "moderators" => Ace.where(admin: false, moderator: true).count, "suspended" => Ace.where.not(suspended_at: nil).count,
      "muted" => Ace.where(suspended_at: nil, id: Mute.active.select(:ace_id)).count }
    @pagy, @aces = pagy(@directory.records, limit: 25)
    ids = @aces.map(&:id)
    @muted_ids = Mute.active.where(ace_id: ids).pluck(:ace_id)
    @warned_ids = PostingWarning.where(ace_id: ids).distinct.pluck(:ace_id)
  rescue ArgumentError => error
    render plain: error.message, status: :bad_request
  end

  def show
    @ace = Ace.find(params[:id])
    @active_mute = @ace.active_posting_mute
    @warning_count = @ace.warnings.count
    @submission_count = Moderation::Queue::TYPES.values.sum { |model| model.where(created_by: @ace).count }
    @spent_cents = Admin::PeopleDirectory.new({}).records.find(@ace.id).spent_cents
    @events_pagy, @events = pagy(SignInEvent.where(ace: @ace).order(created_at: :desc, id: :desc), limit: 25, page_key: "events_page")
    @actions_pagy, @actions = pagy(AccountAction.where(ace: @ace).includes(:actor).order(created_at: :desc, id: :desc), limit: 25, page_key: "actions_page")
  end

  def update
    ace = Ace.find(params[:id])
    attributes = params.permit(:reason, :current_password)
    Admin::ChangeAccount.call(ace: ace, actor: current_ace, action: params.expect(:account_action), role: params[:role],
      reason: attributes[:reason], password: attributes[:current_password], request_key: params.expect(:request_key),
      version: Integer(params.expect(:version).to_s, 10))
    redirect_to admin_person_path(ace), status: :see_other, notice: "Account action recorded."
  rescue Moderation::Review::Forbidden => error
    render plain: error.message, status: :forbidden
  rescue Moderation::Review::Conflict => error
    render plain: error.message, status: :conflict
  rescue ArgumentError, ActiveRecord::RecordInvalid => error
    render plain: error.message, status: :unprocessable_content
  end
end
