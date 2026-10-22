require 'rails_helper'

RSpec.describe "Strength training", type: :request do
  let(:team) { create(:team) }

  before { create_list(:player, 4, team: team, photo_urls: [ "https://example.com/photo.png" ]) }

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

    %w[team_match game_attempts].each do |page|
      it "renders #{page}" do
        get "/strength/#{page}"
        expect(response).to have_http_status(:success)
      end
    end

    { "multiple_choice" => "multiple_choice", "phased_repetition" => "phased_repetition", "images" => "image_recognition" }.each do |page, mode|
      it "redirects #{page} to scoped saved-round setup" do
        get "/strength/#{page}", params: { team_id: team.id }
        expect(response).to redirect_to(new_game_round_path(team_id: team.id, game_type: mode))
      end
    end

    it "redirects the old cipher link into saved-round setup with its scope" do
      get strength_ciphers_path, params: { team_id: team.id, length: 20 }
      expect(response).to redirect_to(new_game_round_path(team_id: team.id, length: 20, game_type: "name_ciphers"))
    end
  end
end
