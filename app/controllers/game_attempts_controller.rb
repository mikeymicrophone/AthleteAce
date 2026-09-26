class GameAttemptsController < ApplicationController
  # Assuming you use Devise and have a helper like `authenticate_ace!`
  before_action :authenticate_ace!
  
  # GET /game_attempts
  # GET /game_attempts.json
  def index
    # Filter by game_type if provided
    scope = current_ace.game_attempts
    scope = scope.where(game_type: params[:game_type]) if params[:game_type].present?
    
    # Limit results
    limit = params[:limit].present? ? params[:limit].to_i : 10
    limit = [limit, 50].min # Cap at 50 for performance
    
    @game_attempts = scope.order(created_at: :desc).limit(limit)
    
    respond_to do |format|
      format.html { redirect_to strength_game_attempts_path }
      format.json do
        render json: @game_attempts.as_json(include: {
          subject_entity: { methods: [:logo_url, :name] },
          target_entity: { methods: [:logo_url, :name] },
          chosen_entity: { methods: [:logo_url, :name] }
        })
      end
    end
  end

  # POST /game_attempts
  def create
    @game_attempt = current_ace.game_attempts.build(game_attempt_params)
    # The answer and correctness are worked out here, not taken from the client
    @game_attempt.target_entity_type = GameAttempt::GAME_TYPES.dig(@game_attempt.game_type, 1)
    @game_attempt.target_entity = @game_attempt.expected_target_entity
    @game_attempt.is_correct = @game_attempt.chose_target?

    if @game_attempt.save
      # Return the saved attempt as JSON with associated entities
      render json: @game_attempt.as_json(include: {
        subject_entity: { methods: [:logo_url, :name] },
        target_entity: { methods: [:logo_url, :name] },
        chosen_entity: { methods: [:logo_url, :name] }
      }), status: :created
    else
      # Log errors for debugging
      Rails.logger.error "Failed to save GameAttempt: #{@game_attempt.errors.full_messages.join(', ')}"
      render json: { errors: @game_attempt.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def game_attempt_params
    params.require(:game_attempt).permit(
      :game_type,
      :subject_entity_id,
      :subject_entity_type,
      :chosen_entity_id,
      :chosen_entity_type,
      :time_elapsed_ms,
      options_presented: [] # Accept options_presented as a simple array of values
    )
  end
end
