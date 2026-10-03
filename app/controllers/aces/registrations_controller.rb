class Aces::RegistrationsController < Devise::RegistrationsController
  protected

  # Keep the saved destination while the ace confirms their email.
  def after_inactive_sign_up_path_for resource
    new_ace_session_path
  end
end
