class Aces::RegistrationsController < Devise::RegistrationsController
  def create
    super do |ace|
      if ace.persisted? && session.delete("devise.google_identity")
        SignInEvent.record!(ace, request, outcome: "success")
      end
    end
  rescue ActiveRecord::RecordNotUnique
    resource.errors.add :base, "This account or handle was just registered. Please sign in or choose another handle."
    clean_up_passwords resource
    set_minimum_password_length
    render :new, status: :unprocessable_content
  end

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
    if (identity = session["devise.google_identity"])
      resource.email = identity.fetch("email")
      resource.google_uid = identity.fetch("uid")
      resource.display_name = identity.fetch("name") unless attributes.key?(:display_name) || attributes.key?("display_name")
      resource.password = Devise.friendly_token(32)
      resource.password_confirmation = nil
      resource.skip_confirmation!
    elsif Rails.env.development? && request.host.end_with?(".test")
      resource.skip_confirmation!
    end
  end

  # Keep the saved destination while the ace confirms their email.
  def after_inactive_sign_up_path_for resource
    new_ace_session_path
  end
end
