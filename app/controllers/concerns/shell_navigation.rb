module ShellNavigation
  extend ActiveSupport::Concern

  included do
    after_action :remember_shell_side
    helper_method :current_side, :current_theme, :available_sides
  end

  def available_sides
    sides = %w[play feed]
    sides << "mod" if current_ace&.can_moderate?
    sides << "admin" if current_ace&.admin?
    sides
  end

  def current_side
    @current_side ||= begin
      owned = case controller_name
      when "play", "play_previews", "strength", "game_rounds", "division_guessing_games", "game_attempts" then "play"
      when "feed", "feed_posts", "shout_out_leaderboards", "shout_out_reactions", "shout_out_drafts", "shout_outs", "wallets", "stripe_purchases", "shout_out_reports" then "feed"
      when "moderation", "reports", "escalations" then "mod"
      when "admin", "people", "shout_out_revenues", "catalog_records", "catalog_edits", "competitions" then "admin"
      when "games" then "admin" if controller_path == "admin/games"
      end
      candidate = owned || params[:side] || session[:side]
      candidate.presence_in(available_sides) || default_side
    end
  end

  def current_theme
    current_ace ? current_ace.theme : cookies[:theme].presence_in(Ace::THEMES) || "system"
  end

  protected

  def after_sign_in_path_for(resource)
    destination = stored_location_for(resource) || shell_landing_path
    return destination if resource.username.present?

    session[:profile_return_to] = destination
    edit_profile_path
  end

  def shell_landing_path
    return feed_path unless current_ace
    side = session[:side].presence_in(available_sides) || default_side
    side = "play" if current_ace && !current_ace.can_moderate?
    case side
    when "feed" then feed_path
    when "mod" then moderation_path
    when "admin" then admin_path
    else strength_path
    end
  end

  private

  def default_side
    return "admin" if current_ace&.admin?
    return "mod" if current_ace&.can_moderate?
    current_ace ? "play" : "feed"
  end

  def remember_shell_side
    return unless request.get? && request.format.html? && response.successful?
    return if devise_controller? || request.xhr? || turbo_frame_request?
    session[:side] = current_side
  end
end
