class ThemePreferencesController < ApplicationController
  def update
    theme = params[:theme].presence_in(Ace::THEMES)
    return head :unprocessable_content unless theme

    if current_ace
      current_ace.update! theme: theme
    else
      cookies.permanent[:theme] = { value: theme, same_site: :lax, httponly: true }
    end
    redirect_back fallback_location: root_path, status: :see_other, notice: "Theme updated."
  end
end
