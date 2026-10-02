module AcesHelper
  def ace_auth_links
    tag.div class: "auth-links" do
      if ace_signed_in?
        link_to(current_ace.email, edit_ace_registration_path, class: "auth-link auth-account") +
          link_to("Sign Out", destroy_ace_session_path, data: { turbo_method: :delete }, class: "auth-button")
      else
        link_to("Sign In", new_ace_session_path, class: "auth-link") +
          link_to("Sign Up", new_ace_registration_path, class: "auth-button")
      end
    end
  end
end
