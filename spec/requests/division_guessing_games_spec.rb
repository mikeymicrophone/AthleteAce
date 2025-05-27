require 'rails_helper'

RSpec.describe "DivisionGuessingGames", type: :request do
  describe "GET /new" do
    it "returns http success" do
      get "/division_guessing_games/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/division_guessing_games/create"
      expect(response).to have_http_status(:success)
    end
  end

end
