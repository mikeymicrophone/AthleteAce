require 'rails_helper'

# Pages that used to raise before the review fixes
RSpec.describe "Page regressions", type: :request do
  it "renders states with their association links" do
    create(:state)
    get states_path
    expect(response).to have_http_status(:success)
  end

  it "renders federations as read-only pages" do
    federation = Federation.create!(name: "FIFA")
    get federations_path
    expect(response).to have_http_status(:success)
    get federation_path(federation)
    expect(response).to have_http_status(:success)
  end

  it "renders spectrums for signed-out visitors" do
    create(:spectrum)
    get spectrums_path
    expect(response).to have_http_status(:success)
  end

  it "accepts a spectrum_id on the players page" do
    get players_path, params: { spectrum_id: create(:spectrum).id }
    expect(response).to have_http_status(:success)
  end

  it "routes filtered pages through associations the models define" do
    sport = create(:sport)
    %w[states countries stadiums contracts activations campaigns conferences divisions].each do |collection|
      get "/sports/#{sport.id}/#{collection}"
      expect(response).to have_http_status(:success), "expected /sports/:id/#{collection} to render"
    end
  end

  context "when signed in" do
    let(:ace) { create(:ace) }
    before { sign_in ace }

    it "shows a message instead of redirecting when no division game can be set up" do
      get new_division_game_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Unable to start a new game")
    end

    it "sends HTML requests for game attempts to the stats page" do
      get game_attempts_path
      expect(response).to redirect_to(strength_game_attempts_path)
    end

    it "renders the per-team game attempts page" do
      team = create(:team)
      get team_strength_game_attempts_path(team)
      expect(response).to have_http_status(:success)
    end
  end

  context "when signed in as an admin" do
    let(:quest) { create(:quest) }
    let(:highlight) { create(:highlight, quest: quest, position: 1) }
    before { sign_in create(:ace, :admin) }

    it "edits a quest highlight" do
      get edit_quest_highlight_path(quest, highlight)
      expect(response).to have_http_status(:success)

      patch quest_highlight_path(quest, highlight), params: { highlight: { position: 4, required: "0" } }
      expect(response).to redirect_to(quest_path(quest))
      expect(highlight.reload).to have_attributes(position: 4, required: false)
    end
  end
end
