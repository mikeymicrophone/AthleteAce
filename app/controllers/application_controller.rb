class ApplicationController < ActionController::Base
  include Pagy::Method
  include ShellNavigation
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include SpectrumsHelper

  # Configure permitted parameters for Devise
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :require_ace_identity, unless: :devise_controller?
  after_action :store_browsing_location, unless: :devise_controller?

  helper_method :admin_signed_in?
  rescue_from ActiveRecord::StaleObjectError do
    render plain: "This content changed while you were editing. Reload and try again.", status: :conflict
  end

  MAX_PER_PAGE = 100

  protected

  # Remember a page the visitor actually viewed, not a background request or an auth form.
  # Devise consumes this local path after a successful sign-in or password reset.
  def store_browsing_location
    return if ace_signed_in? || !request.get? || !request.format.html?
    return if request.xhr? || turbo_frame_request? || !response.successful?
    return unless response.media_type == "text/html"

    store_location_for :ace, request.fullpath
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :username, :display_name, :avatar_color ])
    devise_parameter_sanitizer.permit(:account_update, keys: [])
  end

  def require_ace_identity
    return unless current_ace && current_ace.username.blank?

    session[:profile_return_to] ||= request.fullpath if request.get? && request.format.html? && !request.xhr? && !turbo_frame_request?
    redirect_to edit_profile_path, status: :see_other
  end

  # Page size from ?per_page=, capped so one request can't load a whole table
  def per_page(default = Pagy::OPTIONS[:limit])
    requested = params[:per_page].to_i
    requested.positive? ? [ requested, MAX_PER_PAGE ].min : default
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
