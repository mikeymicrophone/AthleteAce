require "rails_helper"

RSpec.describe "Google sign-in", type: :request do
  before do
    allow(Rails.application.config.x.google_oauth).to receive(:enabled).and_return(true)
  end

  around do |example|
    previous_mode = OmniAuth.config.test_mode
    previous_auth = OmniAuth.config.mock_auth[:google_oauth2]
    OmniAuth.config.test_mode = true
    example.run
  ensure
    OmniAuth.config.test_mode = previous_mode
    OmniAuth.config.mock_auth[:google_oauth2] = previous_auth
  end

  def google_callback(email: "tess.moreno@gmail.com", uid: "123456789", verified: true)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: uid,
      info: { email: email, email_verified: verified, name: "Tess Moreno" },
      credentials: { token: "a-provider-token-that-must-not-be-stored" }
    )
    post ace_google_oauth2_omniauth_authorize_path
    expect(response).to redirect_to(ace_google_oauth2_omniauth_callback_path)
    follow_redirect!
  end

  it "renders a POST Google action alongside email and password when configured" do
    get new_ace_session_path
    page = Nokogiri::HTML(response.body)
    form = page.at_css("form[action='#{ace_google_oauth2_omniauth_authorize_path}']")
    expect(form["method"]).to eq("post")
    expect(form["data-turbo"]).to eq("false")
    expect(form.text).to include("Continue with Google")
    expect(page.at_css("input[type=password]")).to be_present
  end

  it "hides the Google action when credentials are missing" do
    allow(Rails.application.config.x.google_oauth).to receive(:enabled).and_return(false)
    get new_ace_session_path
    expect(response.body).not_to include("Continue with Google")
    expect(response.body).to include("Sign in", "ace_password")
  end

  it "automatically links a verified matching email without changing the password or profile" do
    ace = create(:ace, email: "tess.moreno@gmail.com", display_name: "Courtside Tess")
    destination = player_path(create(:player))
    get destination
    google_callback(email: "TESS.MORENO@gmail.com")
    expect(response).to redirect_to(destination)
    expect(ace.reload.google_uid).to eq("123456789")
    expect(ace.display_name).to eq("Courtside Tess")
    expect(ace.valid_password?("password123")).to be(true)
    expect(SignInEvent.where(ace: ace, outcome: "success").count).to eq(1)
    get profile_path
    expect(response).to have_http_status(:ok)
    expect(request.env["warden"].user(:ace)).to eq(ace)
  end

  it "confirms an existing account when Google verifies its matching email" do
    ace = create(:ace, :unconfirmed, email: "tess.moreno@gmail.com")
    google_callback
    expect(ace.reload).to be_confirmed
    expect(ace.google_uid).to eq("123456789")
    get profile_path
    expect(response).to have_http_status(:ok)
  end

  it "keeps Google's stable identity when its email changes" do
    ace = create(:ace, google_uid: "123456789", email: "original@gmail.com")
    other = create(:ace, email: "changed@gmail.com")
    google_callback(email: other.email)
    expect(ace.reload.email).to eq("original@gmail.com")
    expect(other.reload.google_uid).to be_nil
    get profile_path
    expect(request.env["warden"].user(:ace)).to eq(ace)
  end

  it "rejects unverified email claims without linking or signing in" do
    ace = create(:ace, email: "tess.moreno@gmail.com")
    google_callback(verified: false)
    expect(response).to redirect_to(new_ace_session_path)
    expect(ace.reload.google_uid).to be_nil
    expect(SignInEvent.count).to eq(0)
    get profile_path
    expect(response).to redirect_to(new_ace_session_path)
  end

  it "does not replace another bound Google identity" do
    ace = create(:ace, google_uid: "987654321", email: "tess.moreno@gmail.com")
    google_callback
    expect(response).to redirect_to(new_ace_session_path)
    expect(ace.reload.google_uid).to eq("987654321")
    expect(SignInEvent.count).to eq(0)
  end

  it "does not link or sign into a suspended account" do
    ace = create(:ace, email: "tess.moreno@gmail.com", suspended_at: Time.current)
    google_callback
    expect(response).to redirect_to(new_ace_session_path)
    expect(ace.reload.google_uid).to be_nil
    get profile_path
    expect(response).to redirect_to(new_ace_session_path)
  end

  it "finishes a new Google signup with a chosen handle and preserves the original destination" do
    destination = player_path(create(:player))
    get destination
    expect { google_callback }.not_to change(Ace, :count)
    expect(response).to redirect_to(new_ace_registration_path)
    expect(request.session.fetch("devise.google_identity").keys).to match_array(%w[uid email name])
    follow_redirect!
    page = Nokogiri::HTML(response.body)
    expect(page.at_css("input[type=password]")).to be_nil
    expect(page.at_css("input[name='ace[email]']")["readonly"]).to be_present
    post ace_registration_path, params: { ace: {
      username: "courtside_tess", display_name: "Tess at the Garden", email: "tampered@example.com",
      google_uid: "tampered", password: "tampered", admin: true
    } }
    expect(response).to redirect_to(destination)
    ace = Ace.find_by!(email: "tess.moreno@gmail.com")
    expect(ace).to be_confirmed
    expect(ace.google_uid).to eq("123456789")
    expect(ace.username).to eq("courtside_tess")
    expect(ace.display_name).to eq("Tess at the Garden")
    expect(ace).not_to be_admin
    expect(ace.valid_password?("tampered")).to be(false)
    expect(request.session["devise.google_identity"]).to be_nil
    expect(SignInEvent.where(ace: ace, outcome: "success").count).to eq(1)
  end

  it "keeps the verified signup state across a handle validation error" do
    create(:ace, username: "courtside_tess")
    google_callback
    post ace_registration_path, params: { ace: { username: "courtside_tess", display_name: "Tess Moreno" } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(request.session["devise.google_identity"]).to be_present
    post ace_registration_path, params: { ace: { username: "garden_tess", display_name: "Tess Moreno" } }
    expect(Ace.find_by!(email: "tess.moreno@gmail.com").username).to eq("garden_tess")
  end

  it "does not accept a Google identity supplied directly to password registration" do
    post ace_registration_path, params: { ace: { username: "garden_tess", display_name: "Tess Moreno",
      email: "tess@example.com", password: "password123", password_confirmation: "password123", google_uid: "123456789" } }
    ace = Ace.find_by!(email: "tess@example.com")
    expect(ace.google_uid).to be_nil
    expect(ace).not_to be_confirmed
  end

  it "clears pending Google signup when choosing another account" do
    google_callback
    get cancel_ace_registration_path
    expect(request.session["devise.google_identity"]).to be_nil
    follow_redirect!
    expect(response.body).to include("Continue with Google", "ace_password")
  end

  it "handles provider cancellation without displaying provider-supplied error text" do
    OmniAuth.config.mock_auth[:google_oauth2] = :access_denied
    post ace_google_oauth2_omniauth_authorize_path
    follow_redirect!
    expect(response).to redirect_to(new_ace_session_path)
    follow_redirect!
    expect(response.body).to include("Google sign-in was cancelled or could not be completed.")
    expect(response.body).not_to include("access_denied")
  end

  it "requires a valid Rails CSRF token and POST for the request phase" do
    previous_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(provider: "google_oauth2", uid: "123456789", info: { email: "tess@gmail.com", email_verified: true })
    get ace_google_oauth2_omniauth_authorize_path
    expect(response).to have_http_status(:not_found)
    post ace_google_oauth2_omniauth_authorize_path
    expect(response).not_to redirect_to(ace_google_oauth2_omniauth_callback_path)
    get new_ace_session_path
    page = Nokogiri::HTML(response.body)
    token = page.at_css("form[action='#{ace_google_oauth2_omniauth_authorize_path}'] input[name=authenticity_token]")["value"]
    post ace_google_oauth2_omniauth_authorize_path, params: { authenticity_token: token }
    expect(response).to redirect_to(ace_google_oauth2_omniauth_callback_path)
  ensure
    ActionController::Base.allow_forgery_protection = previous_protection
  end
end
