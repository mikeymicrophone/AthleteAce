require 'rails_helper'

RSpec.describe "GameAttempts", type: :request do
  describe "GET /create" do
    it "returns http success" do
      get "/game_attempts/create"
      expect(response).to have_http_status(:success)
    end
  end

end
