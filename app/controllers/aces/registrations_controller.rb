class Aces::RegistrationsController < Devise::RegistrationsController
  def destroy
    unless resource.destroy
      alert = if resource.errors.of_kind?(:base, :last_active_admin)
        "Your account is the last active admin. Another confirmed admin must remain before you can close it."
      else
        "Your account has financial records and cannot be deleted here. Contact support to arrange account closure."
      end
      redirect_to edit_ace_registration_path, status: :see_other, alert: alert
      return
    end

    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    set_flash_message! :notice, :destroyed
    redirect_to after_sign_out_path_for(resource_name), status: :see_other
  end

  protected

  def build_resource(attributes = {})
    super
    resource.skip_confirmation! if Rails.env.development? && request.host.end_with?(".test")
  end

  # Keep the saved destination while the ace confirms their email.
  def after_inactive_sign_up_path_for resource
    new_ace_session_path
  end
end
