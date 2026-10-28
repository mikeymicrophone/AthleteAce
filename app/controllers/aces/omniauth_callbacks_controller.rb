class Aces::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    session.delete("devise.google_identity")
    ace = Ace.from_google(request.env["omniauth.auth"])
    if ace.persisted?
      SignInEvent.record!(ace, request, outcome: "success")
      sign_in_and_redirect ace, event: :authentication
    else
      session["devise.google_identity"] = { "uid" => ace.google_uid, "email" => ace.email, "name" => ace.display_name }
      redirect_to new_ace_registration_path, status: :see_other
    end
  rescue Ace::GoogleAuthenticationError => error
    redirect_to new_ace_session_path, status: :see_other, alert: error.message
  end

  def failure
    session.delete("devise.google_identity")
    redirect_to new_ace_session_path, status: :see_other, alert: "Google sign-in was cancelled or could not be completed. Please try again."
  end
end
