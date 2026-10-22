class ModerationController < ApplicationController
  before_action :authenticate_ace!
  before_action :require_reviewer
  before_action :set_item, only: %i[show update compare]
  before_action :set_queue, only: %i[index show update compare]
  helper_method :queue_context

  def index
    @items = @queue.items
  end

  def show
    @previous_item, @next_item = @queue.neighbors(@item)
    @position = @queue.items.index(@item)
    @providers = DecisionModels::Client::CONFIG.keys.map { |provider| DecisionModels::Client.new(provider) }
    @evaluations = @item.decision_evaluations.order(created_at: :desc).limit(20)
    @decisions = @item.moderation_decisions.includes(:actor).order(created_at: :desc, id: :desc).limit(100)
  end

  def update
    Moderation::Review.call(record: @item, actor: current_ace, action: params.require(:decision),
      revision: params.require(:revision).to_i, status: params.require(:status), reason: params[:reason])
    redirect_to moderation_item_path(type: @item.class.name, id: @item.id, **queue_context), status: :see_other, notice: "Decision recorded."
  rescue Moderation::Review::Forbidden => error
    render plain: error.message, status: :forbidden
  rescue Moderation::Review::Conflict => error
    render plain: error.message, status: :conflict
  rescue ArgumentError => error
    render plain: error.message, status: :unprocessable_content
  end

  def compare
    DecisionModels::Compare.call(task: DecisionModels::Policies.content(state: @item.moderation_snapshot), subject: @item,
      comparison_key: params.require(:comparison_key))
    redirect_to moderation_item_path(type: @item.class.name, id: @item.id, **queue_context), status: :see_other,
      notice: "Comparison recorded. The submission status has not changed."
  rescue ArgumentError => error
    render plain: error.message, status: :conflict
  end

  def log
    response.headers["Cache-Control"] = "private, no-store"
    @log = Moderation::DecisionLog.new(from: params[:from], through: params[:through], type: params[:item_type],
      actor_id: params[:actor_id], action: params[:decision_action])
    respond_to do |format|
      format.html do
        @actors = Ace.where(id: ModerationDecision.select(:actor_id)).order(:username, :id)
        @pagy, @decisions = pagy(@log.records, limit: 25)
      end
      format.csv do
        send_data @log.csv, type: "text/csv", filename: "athleteace-decisions-#{@log.from}-#{@log.through}.csv"
      end
    end
  rescue ArgumentError => error
    render plain: error.message, status: :bad_request
  end

  private

  def set_item
    model = Moderation::Queue::TYPES[params[:type]] || raise(ActiveRecord::RecordNotFound)
    @item = model.find(params[:id])
  end

  def set_queue
    status = params[:queue_status] || (params[:status] if action_name == "index")
    @queue = Moderation::Queue.new(reviewer: current_ace, status: status, type: params[:item_type], page: params[:page])
  end

  def queue_context
    { queue_status: @queue.status, item_type: @queue.type, page: @queue.page }
  end

  def require_reviewer
    return if current_ace.can_moderate?
    head :forbidden
  end
end
