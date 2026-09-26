class ApplicationController < ActionController::Base
  include Pagy::Backend
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  include SpectrumsHelper
  
  # Configure permitted parameters for Devise
  before_action :configure_permitted_parameters, if: :devise_controller?

  helper_method :admin_signed_in?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [])
    devise_parameter_sanitizer.permit(:account_update, keys: [])
  end

  def admin_signed_in?
    ace_signed_in? && current_ace.admin?
  end

  # Use after authenticate_ace! to limit an action to admins
  def require_admin!
    return if admin_signed_in?

    if request.format.json?
      head :forbidden
    else
      redirect_back fallback_location: root_path, status: :see_other, alert: "Only admins can do that."
    end
  end
end
