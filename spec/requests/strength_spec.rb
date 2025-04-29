require 'rails_helper'

RSpec.describe "Strengths", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/strength/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /multiple_choice" do
    it "returns http success" do
      get "/strength/multiple_choice"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /phased_repetition" do
    it "returns http success" do
      get "/strength/phased_repetition"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /images" do
    it "returns http success" do
      get "/strength/images"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /ciphers" do
    it "returns http success" do
      get "/strength/ciphers"
      expect(response).to have_http_status(:success)
    end
  end

end
