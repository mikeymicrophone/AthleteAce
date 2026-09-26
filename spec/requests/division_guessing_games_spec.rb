require 'rails_helper'

RSpec.describe "DivisionGuessingGames", type: :request do
  let(:conference) { create(:conference) }
  let!(:team) do
    divisions = create_list(:division, 3, conference: conference)
    create(:team, league: conference.league).tap { |team| create(:membership, team: team, division: divisions.first) }
  end

  before { sign_in create(:ace) }

  it "asks about a team's division" do
    get new_division_game_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include(team.name)
  end

  it "sets up the next question for HTML requests by redirecting once" do
    post create_division_game_attempt_path
    expect(response).to redirect_to(new_division_game_path)
  end
end
