class AdminPasswordResetJob < ApplicationJob
  def perform(action_id)
    action = AccountAction.find_by(id: action_id, action: "password_reset")
    action&.ace&.send_reset_password_instructions
  end
end
