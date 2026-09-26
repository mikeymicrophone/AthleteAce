require 'rails_helper'

RSpec.describe "Seasons", type: :request do
  let!(:season) { create(:season) }

  it "lists seasons" do
    get seasons_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include(season.league.name)
  end

  it "shows a season" do
    get season_path(season)
    expect(response).to have_http_status(:success)
  end
end
