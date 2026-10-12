class ApplicationController < ActionController::Base
  include Pagy::Backend
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  include SpectrumsHelper
  
  # Configure permitted parameters for Devise
  before_action :configure_permitted_parameters, if: :devise_controller?

  helper_method :admin_signed_in?, :can_manage?

  MAX_PER_PAGE = 100

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [])
    devise_parameter_sanitizer.permit(:account_update, keys: [])
  end

  # Page size from ?per_page=, capped so one request can't load a whole table
  def per_page(default = Pagy::DEFAULT[:limit])
    requested = params[:per_page].to_i
    requested.positive? ? [requested, MAX_PER_PAGE].min : default
  end

  def admin_signed_in?
    ace_signed_in? && current_ace.admin?
  end

  # Admins can manage anything; other aces can manage the records they created
  def can_manage?(record)
    admin_signed_in? || (ace_signed_in? && record.respond_to?(:creator) && record.creator == current_ace)
  end

  # Use after authenticate_ace! to limit an action to admins
  def require_admin!
    deny_access "Only admins can do that." unless admin_signed_in?
  end

  # Use after authenticate_ace! to limit an action to the record's creator and admins
  def require_manager!(record)
    deny_access "Only its creator or an admin can do that." unless can_manage?(record)
  end

  def deny_access(message)
    if request.format.json?
      head :forbidden
    else
      redirect_back fallback_location: root_path, status: :see_other, alert: message
    end
  end
end
