module AcesHelper
  def ace_auth_links
    if ace_signed_in?
      content_tag :div, class: "flex items-center space-x-4" do
        concat(link_to(current_ace.email, edit_ace_registration_path, class: "text-white hover:text-orange-200"))
        concat(link_to("Sign Out", destroy_ace_session_path, data: { turbo_method: :delete }, class: "bg-orange-500 hover:bg-orange-600 text-white px-3 py-1 rounded-md text-sm"))
      end
    else
      content_tag :div, class: "flex items-center space-x-4" do
        concat(link_to("Sign In", new_ace_session_path, class: "text-white hover:text-orange-200"))
        concat(link_to("Sign Up", new_ace_registration_path, class: "bg-orange-500 hover:bg-orange-600 text-white px-3 py-1 rounded-md text-sm"))
      end
    end
  end
end
