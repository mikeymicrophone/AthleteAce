class GameAttemptsController < ApplicationController
  # Assuming you use Devise and have a helper like `authenticate_ace!`
  before_action :authenticate_ace!

  # POST /game_attempts
  def create
    @game_attempt = current_ace.game_attempts.build(game_attempt_params)

    if @game_attempt.save
      # Respond with success, no content needed back usually
      head :created
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
      :target_entity_id,
      :target_entity_type,
      :chosen_entity_id,
      :chosen_entity_type,
      :is_correct,
      :time_elapsed_ms,
      options_presented: [:id, :type, :name] # Permit array of objects with these keys
    )
  end
end
