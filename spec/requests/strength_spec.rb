require 'rails_helper'

RSpec.describe "Strength training", type: :request do
  let(:team) { create(:team) }

  before { create_list(:player, 4, team: team, photo_urls: ["https://example.com/photo.png"]) }

  it "shows the dashboard to visitors" do
    get strength_path
    expect(response).to have_http_status(:success)
  end

  it "asks visitors to sign in before playing" do
    get strength_multiple_choice_path
    expect(response).to redirect_to(new_ace_session_path)
  end

  context "when signed in" do
    before { sign_in create(:ace) }

    %w[multiple_choice phased_repetition images ciphers team_match game_attempts].each do |page|
      it "renders #{page}" do
        get "/strength/#{page}"
        expect(response).to have_http_status(:success)
      end
    end
  end
end
