class ModerationController < ApplicationController
  TYPES = { "Quest" => Quest, "Achievement" => Achievement, "Highlight" => Highlight, "Spectrum" => Spectrum }.freeze
  before_action :authenticate_ace!
  before_action :require_reviewer
  before_action :set_item, only: %i[show update compare]

  def index
    @status = params[:status].presence_in(%w[pending approved rejected hidden]) || "pending"
    @items = TYPES.values.flat_map { |model|
      model.where(moderation_status: @status).where.not(created_by_id: current_ace.id).or(
        model.where(moderation_status: @status, created_by_id: nil)
      ).includes(:created_by).order(:created_at, :id).limit(100).to_a
    }.sort_by { |item| [ item.created_at, item.class.name, item.id ] }.first(100)
  end

  def show
    @evaluations = @item.decision_evaluations.order(created_at: :desc).limit(20)
    @decisions = @item.moderation_decisions.includes(:actor).order(created_at: :desc, id: :desc).limit(100)
  end

  def update
    Moderation::Review.call(record: @item, actor: current_ace, action: params.require(:decision),
      revision: params.require(:revision).to_i, status: params.require(:status), reason: params[:reason])
    redirect_to moderation_item_path(type: @item.class.name, id: @item.id), status: :see_other, notice: "Decision recorded."
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
    redirect_to moderation_item_path(type: @item.class.name, id: @item.id), status: :see_other,
      notice: "Comparison recorded. The submission status has not changed."
  rescue ArgumentError => error
    render plain: error.message, status: :conflict
  end

  def log
    @decisions = ModerationDecision.includes(:actor).order(created_at: :desc, id: :desc).limit(100)
  end

  private

  def set_item
    model = TYPES[params[:type]] || raise(ActiveRecord::RecordNotFound)
    @item = model.find(params[:id])
  end

  def require_reviewer
    return if current_ace.can_moderate?
    head :forbidden
  end
end
