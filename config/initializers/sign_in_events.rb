Warden::Manager.before_failure do |env, options|
  request = ActionDispatch::Request.new(env)
  if options[:scope] == :ace && request.post? && options[:attempted_path].to_s.split("?").first == Rails.application.routes.url_helpers.ace_session_path
    credentials = request.params["ace"]
    email = credentials["email"] if credentials.is_a?(Hash)
    if email.is_a?(String) && (ace = Ace.find_for_database_authentication(email: email.strip.downcase))
      SignInEvent.record!(ace, request, outcome: "failure")
    end
  end
end
