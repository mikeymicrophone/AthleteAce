require 'rails_helper'

RSpec.describe "Important Pages Rendering", type: :request do
  # Set up minimal test data for request specs
  let!(:sport) { create(:sport) }
  let!(:country) { create(:country) }
  let!(:state) { create(:state, country: country) }
  let!(:city) { create(:city, state: state) }
  let!(:stadium) { create(:stadium, city: city) }
  let!(:league) { create(:league, sport: sport, jurisdiction: country) }
  let!(:conference) { create(:conference, league: league) }
  let!(:division) { create(:division, conference: conference) }
  let!(:team) { create(:team, league: league, stadium: stadium) }
  let!(:player) { create(:player, team: team) }
  let!(:quest) { create(:quest) }
  let!(:spectrum) { create(:spectrum) }
  let!(:achievement) { create(:achievement) }

  describe "Index Pages for Browsable Resources" do
    it "GET /sports renders successfully" do
      get sports_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(sport.name)
    end

    it "GET /leagues renders successfully" do
      get leagues_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(league.name)
    end

    it "GET /conferences renders successfully" do
      get conferences_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(conference.name)
    end

    it "GET /divisions renders successfully" do
      get divisions_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(division.name)
    end

    it "GET /teams renders successfully" do
      get teams_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(team.territory || team.mascot)
    end

    it "GET /players renders successfully" do
      get players_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(player.first_name)
    end

    it "GET /stadiums renders successfully" do
      get stadiums_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(stadium.name)
    end

    it "GET /cities renders successfully" do
      get cities_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(city.name)
    end

    it "GET /states renders successfully" do
      get states_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(state.name)
    end

    it "GET /countries renders successfully" do
      get countries_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(country.name)
    end

    it "GET /quests renders successfully" do
      get quests_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(quest.name)
    end

    it "GET /spectrums renders successfully" do
      get spectrums_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(spectrum.name)
    end

    it "GET /achievements renders successfully" do
      get achievements_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(achievement.name)
    end
  end

  describe "Show Pages for Detailed Resources" do
    it "GET /leagues/:id renders successfully" do
      get league_path(league)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(league.name)
    end

    it "GET /teams/:id renders successfully" do
      get team_path(team)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(team.territory || team.mascot)
    end

    it "GET /players/:id renders successfully" do
      get player_path(player)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(player.first_name)
      expect(response.body).to include(player.last_name)
    end

    it "GET /stadiums/:id renders successfully" do
      get stadium_path(stadium)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(stadium.name)
    end

    it "GET /cities/:id renders successfully" do
      get city_path(city)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(city.name)
    end

    it "GET /states/:id renders successfully" do
      get state_path(state)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(state.name)
    end

    it "GET /countries/:id renders successfully" do
      get country_path(country)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(country.name)
    end

    it "GET /quests/:id renders successfully" do
      get quest_path(quest)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(quest.name)
    end

    it "GET /conferences/:id renders successfully" do
      get conference_path(conference)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(conference.name)
    end

    it "GET /divisions/:id renders successfully" do
      get division_path(division)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(division.name)
    end
  end

  describe "Game Play Pages" do
    it "GET /strength/team_match renders successfully" do
      get strength_team_match_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("game-container")
    end

    it "GET /play/guess-the-division renders successfully" do
      get new_division_game_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("game-container")
    end
  end

  describe "Game Review Pages" do
    let!(:game_attempt) { create(:game_attempt, target_entity: team, subject_entity: player) }

    it "GET /strength/game_attempts renders successfully" do
      get strength_game_attempts_path
      expect(response).to have_http_status(:success)
    end

    it "GET /teams/:id/strength/game_attempts renders successfully" do
      get team_strength_game_attempts_path(team)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(team.territory || team.mascot)
    end
  end

  describe "Filterable Pages" do
    it "renders filtered teams by league" do
      get "/leagues/#{league.id}/teams"
      expect(response).to have_http_status(:success)
      expect(response.body).to include(team.territory || team.mascot)
      expect(response.body).to include(league.name)
    end

    it "renders filtered players by team" do
      get "/teams/#{team.id}/players"
      expect(response).to have_http_status(:success)
      expect(response.body).to include(player.first_name)
      expect(response.body).to include(team.territory || team.mascot)
    end

    it "renders filtered teams by sport" do
      get "/sports/#{sport.id}/teams"
      expect(response).to have_http_status(:success)
      expect(response.body).to include(team.territory || team.mascot)
      expect(response.body).to include(sport.name)
    end

    it "renders filtered players by league" do
      get "/leagues/#{league.id}/players"
      expect(response).to have_http_status(:success)
      expect(response.body).to include(player.first_name)
      expect(response.body).to include(league.name)
    end

    it "renders deeply nested filtered teams" do
      get "/sports/#{sport.id}/leagues/#{league.id}/teams"
      expect(response).to have_http_status(:success)
      expect(response.body).to include(team.territory || team.mascot)
      expect(response.body).to include(sport.name)
      expect(response.body).to include(league.name)
    end

    it "renders deeply nested filtered players" do
      get "/sports/#{sport.id}/leagues/#{league.id}/teams/#{team.id}/players"
      expect(response).to have_http_status(:success)
      expect(response.body).to include(player.first_name)
      expect(response.body).to include(sport.name)
      expect(response.body).to include(league.name)
    end
  end

  describe "Authentication-aware pages" do
    let(:ace) { create(:ace) }

    context "when signed in" do
      it "renders quest page with authentication features" do
        post ace_session_path, params: { ace: { email: ace.email, password: ace.password } }
        get quest_path(quest)
        expect(response).to have_http_status(:success)
        expect(response.body).to include(quest.name)
        expect(response.body).to include("Begin Quest")
      end

      it "renders random quest discovery page" do
        post ace_session_path, params: { ace: { email: ace.email, password: ace.password } }
        get "/quests/random"
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Quest Discovery")
      end
    end

    context "when not signed in" do
      it "renders quest page without authentication features" do
        get quest_path(quest)
        expect(response).to have_http_status(:success)
        expect(response.body).to include(quest.name)
        expect(response.body).not_to include("Begin Quest")
      end

      it "redirects from random quest discovery page" do
        get "/quests/random"
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "Error handling" do
    it "handles missing resources with 404" do
      get team_path(99999)
      expect(response).to have_http_status(:not_found)
    end

    it "handles missing players with 404" do
      get player_path(99999)
      expect(response).to have_http_status(:not_found)
    end

    it "handles missing leagues with 404" do
      get league_path(99999)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "Content validation" do
    it "includes navigation elements in all index pages" do
      [sports_path, leagues_path, teams_path, players_path].each do |path|
        get path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("navigation")
      end
    end

    it "includes index collection structure in list pages" do
      [sports_path, leagues_path, teams_path, players_path].each do |path|
        get path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("index-collection")
      end
    end

    it "includes filterable UI in filterable pages" do
      get teams_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("filter") # Some filter-related content should be present
    end
  end
end