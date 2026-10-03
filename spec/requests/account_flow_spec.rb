require "rails_helper"

RSpec.describe "Account flow", type: :request do
  let(:ace) { create(:ace) }
  let(:player) { create(:player) }

  it "returns to the viewed player after failed then successful sign-in, ignoring external return parameters" do
    destination = team_player_path(player.team, player, source: "rating")
    get destination
    get new_ace_session_path, params: { return_to: "https://example.net/steal" }
    post ace_session_path, params: { ace: { email: ace.email, password: "wrong-password" } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Invalid email or password.")
    post ace_session_path, params: { ace: { email: ace.email, password: "password123" } }
    expect(response).to redirect_to(destination)
  end

  it "does not replace the destination with background HTML or spectrum requests" do
    get player_path(player)
    get teams_path, headers: { "Turbo-Frame" => "background" }
    get for_spectrums_player_ratings_path(player), params: { spectrum_ids: "" }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    get new_ace_password_path
    get new_ace_session_path
    post ace_session_path, params: { ace: { email: ace.email, password: "password123" } }
    expect(response).to redirect_to(player_path(player))
  end

  it "returns to a protected game when sign-in was required" do
    destination = strength_team_match_path(team_id: player.team_id)
    get destination
    expect(response).to redirect_to(new_ace_session_path)
    post ace_session_path, params: { ace: { email: ace.email, password: "password123" } }
    expect(response).to redirect_to(destination)
  end

  it "keeps the player destination through registration and email confirmation" do
    get player_path(player)
    get new_ace_registration_path
    post ace_registration_path, params: { ace: { email: "new-ace@example.com", password: "password123", password_confirmation: "password123" } }
    expect(response).to redirect_to(new_ace_session_path)
    follow_redirect!
    new_ace = Ace.find_by! email: "new-ace@example.com"
    expect(new_ace).not_to be_confirmed
    new_ace.confirm
    post ace_session_path, params: { ace: { email: new_ace.email, password: "password123" } }
    expect(response).to redirect_to(player_path(player))
  end

  it "preserves the reset token and returns to the player after a password reset" do
    get player_path(player)
    token, digest = Devise.token_generator.generate Ace, :reset_password_token
    ace.update! reset_password_token: digest, reset_password_sent_at: Time.current
    get edit_ace_password_path(reset_password_token: token)
    expect(response.body).to include("New password", token)
    put ace_password_path, params: { ace: { reset_password_token: token, password: "replacement123", password_confirmation: "replacement123" } }
    expect(response).to redirect_to(player_path(player))
    expect(ace.reload.valid_password?("replacement123")).to be(true)
  end

  it "renders useful errors for invalid registration and expired reset tokens" do
    post ace_registration_path, params: { ace: { email: "bad", password: "short", password_confirmation: "different" } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("account-errors", "Email is invalid", "Password confirmation")
    put ace_password_path, params: { ace: { reset_password_token: "expired", password: "replacement123", password_confirmation: "replacement123" } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Reset password token is invalid", "account-errors")
  end
end
