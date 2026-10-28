require "rails_helper"

RSpec.describe "Local account confirmation", type: :request do
  before do
    host! host
    allow(Rails.env).to receive(:development?).and_return(development)
  end

  let(:host) { "athleteace.test" }
  let(:development) { true }
  let(:email) { "local-ace@example.com" }

  def register
    post ace_registration_path, params: { ace: { username: "courtside_sam", display_name: "Sam Carter", email: email, password: "password123", password_confirmation: "password123" } }
  end

  def log_in(password = "password123")
    post ace_session_path, params: { ace: { email: email.upcase, password: password } }
  end

  it "confirms registration without mail and signs in at the saved page" do
    get strength_path
    expect { register }.not_to change(ActionMailer::Base.deliveries, :count)
    expect(Ace.find_by!(email: email)).to be_confirmed
    expect(response).to redirect_to(strength_path)
    get strength_path
    expect(response.body).to include(destroy_ace_session_path)
  end

  it "confirms an existing account after a correct password and signs in at the saved page" do
    account = create(:ace, :unconfirmed, email: email)
    get strength_path
    expect { log_in }.not_to change(ActionMailer::Base.deliveries, :count)
    expect(account.reload).to be_confirmed
    expect(response).to redirect_to(strength_path)
    get strength_path
    expect(response.body).to include(destroy_ace_session_path)
  end

  it "does not confirm an account after a wrong password" do
    account = create(:ace, :unconfirmed, email: email)
    log_in("incorrect")
    expect(account.reload).not_to be_confirmed
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "keeps registration validation" do
    expect {
      post ace_registration_path, params: { ace: { email: email, password: "short", password_confirmation: "different" } }
    }.not_to change(Ace, :count)
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "handles an unknown login without creating an account" do
    expect { log_in }.not_to change(Ace, :count)
    expect(response).to have_http_status(:unprocessable_content)
  end

  shared_examples "email confirmation required" do
    it "keeps new registrations unconfirmed and sends confirmation mail" do
      expect { register }.to change(ActionMailer::Base.deliveries, :count).by(1)
      expect(Ace.find_by!(email: email)).not_to be_confirmed
      expect(response).to redirect_to(new_ace_session_path)
    end

    it "does not confirm existing accounts during login" do
      account = create(:ace, :unconfirmed, email: email)
      log_in
      expect(account.reload).not_to be_confirmed
      expect(response).to redirect_to(new_ace_session_path)
      expect(flash[:alert]).to eq("You have to confirm your email address before continuing.")
    end
  end

  context "on another host in development" do
    let(:host) { "athleteace.example.com" }

    include_examples "email confirmation required"
  end

  context "on a hostname that contains but does not end in .test" do
    let(:host) { "athleteace.test.example.com" }

    include_examples "email confirmation required"
  end

  context "outside development on a .test host" do
    let(:development) { false }

    include_examples "email confirmation required"
  end
end
