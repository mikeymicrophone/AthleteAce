require 'rails_helper'

RSpec.describe "Important Pages Rendering", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  # Set up test data - we'll create a complete hierarchy for testing
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
    it "renders Sports index page" do
      visit sports_path
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(sport.name)
      expect(page).to have_css(".index-collection") # Generic index structure
    end

    it "renders Leagues index page" do
      visit leagues_path
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(league.name)
      expect(page).to have_css(".index-collection")
    end

    it "renders Conferences index page" do
      visit conferences_path
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(conference.name)
      expect(page).to have_css(".index-collection")
    end

    it "renders Divisions index page" do
      visit divisions_path
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(division.name)
      expect(page).to have_css(".index-collection")
    end

    it "renders Teams index page" do
      visit teams_path
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(team.territory || team.mascot)
      expect(page).to have_css(".index-collection")
    end

    it "renders Players index page" do
      visit players_path
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(player.first_name)
      expect(page).to have_css(".index-collection")
    end

    it "renders Stadiums index page" do
      visit stadiums_path
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(stadium.name)
      expect(page).to have_css(".index-collection")
    end

    it "renders Cities index page" do
      visit cities_path
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(city.name)
      expect(page).to have_css(".index-collection")
    end

    it "renders States index page" do
      visit states_path
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(state.name)
      expect(page).to have_css(".index-collection")
    end

    it "renders Countries index page" do
      visit countries_path
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(country.name)
      expect(page).to have_css(".index-collection")
    end

    it "renders Quests index page" do
      visit quests_path
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(quest.name)
    end

    it "renders Spectrums index page" do
      visit spectrums_path
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(spectrum.name)
    end

    it "renders Achievements index page" do
      visit achievements_path
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(achievement.name)
    end
  end

  describe "Show Pages for Detailed Resources" do
    it "renders League show page" do
      visit league_path(league)
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(league.name)
      expect(page).to have_css(".show-header", text: league.name)
    end

    it "renders Team show page" do
      visit team_path(team)
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(team.territory || team.mascot)
    end

    it "renders Player show page" do
      visit player_path(player)
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(player.first_name)
      expect(page).to have_content(player.last_name)
    end

    it "renders Stadium show page" do
      visit stadium_path(stadium)
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(stadium.name)
    end

    it "renders City show page" do
      visit city_path(city)
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(city.name)
    end

    it "renders State show page" do
      visit state_path(state)
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(state.name)
    end

    it "renders Country show page" do
      visit country_path(country)
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(country.name)
    end

    it "renders Quest show page" do
      visit quest_path(quest)
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(quest.name)
    end

    it "renders Conference show page" do
      visit conference_path(conference)
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(conference.name)
    end

    it "renders Division show page" do
      visit division_path(division)
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(division.name)
    end
  end

  describe "Game Play Pages" do
    it "renders Team Match Game page" do
      visit strength_team_match_path
      
      expect(page).to have_http_status(:success)
      expect(page).to have_css(".game-container")
      expect(page).to have_content("Who does")
    end

    it "renders Division Guess Game page" do
      visit new_division_game_path
      
      expect(page).to have_http_status(:success)
      expect(page).to have_css(".game-container")
      expect(page).to have_content("division")
    end
  end

  describe "Game Review Pages" do
    let!(:game_attempt) { create(:game_attempt, target_entity: team, subject_entity: player) }

    it "renders Game Attempts Review Page" do
      visit strength_game_attempts_path
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content("Game Attempts") 
    end

    it "renders Team Attempts Review Page" do
      visit team_strength_game_attempts_path(team)
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(team.territory || team.mascot)
    end
  end

  describe "Filterable Index Pages" do
    it "renders filtered Teams by League" do
      visit "/leagues/#{league.id}/teams"
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(team.territory || team.mascot)
      expect(page).to have_content(league.name) # Should show filter context
    end

    it "renders filtered Players by Team" do
      visit "/teams/#{team.id}/players"
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(player.first_name)
      expect(page).to have_content(team.territory || team.mascot) # Should show filter context
    end

    it "renders filtered Teams by Sport" do
      visit "/sports/#{sport.id}/teams"
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(team.territory || team.mascot)
      expect(page).to have_content(sport.name) # Should show filter context
    end

    it "renders filtered Players by League" do
      visit "/leagues/#{league.id}/players"
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(player.first_name)
      expect(page).to have_content(league.name) # Should show filter context
    end
  end

  describe "Complex filtered views" do
    it "renders deeply nested filtered Teams" do
      visit "/sports/#{sport.id}/leagues/#{league.id}/teams"
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(team.territory || team.mascot)
      # Should show multiple filter breadcrumbs
      expect(page).to have_content(sport.name)
      expect(page).to have_content(league.name)
    end

    it "renders deeply nested filtered Players" do
      visit "/sports/#{sport.id}/leagues/#{league.id}/teams/#{team.id}/players"
      
      expect(page).to have_http_status(:success)
      expect(page).to have_content(player.first_name)
      # Should show multiple filter breadcrumbs
      expect(page).to have_content(sport.name)
      expect(page).to have_content(league.name)
      expect(page).to have_content(team.territory || team.mascot)
    end
  end

  describe "Pages with rating functionality", :js do
    let!(:rating) { create(:rating, target: player, spectrum: spectrum) }

    it "renders Players index with rating slider" do
      visit players_path
      
      expect(page).to have_http_status(:success)
      expect(page).to have_css("[data-controller='spectrum-picker']")
      expect(page).to have_content(spectrum.name.sub(/\s*\(.*\)\s*$/, '').strip)
    end

    it "renders Teams index with rating slider" do
      visit teams_path
      
      expect(page).to have_http_status(:success)
      expect(page).to have_css("[data-controller='spectrum-picker']")
    end
  end

  describe "Authentication required pages" do
    let(:ace) { create(:ace) }

    context "when signed in" do
      before { sign_in ace }

      it "renders quest with begin quest button" do
        visit quest_path(quest)
        
        expect(page).to have_http_status(:success)
        expect(page).to have_button("Begin Quest")
      end

      it "allows access to random quest discovery" do
        visit "/quests/random"
        
        expect(page).to have_http_status(:success)
        expect(page).to have_content("Quest Discovery")
      end
    end

    context "when not signed in" do
      it "renders quest without begin quest button" do
        visit quest_path(quest)
        
        expect(page).to have_http_status(:success)
        expect(page).not_to have_button("Begin Quest")
      end
    end
  end

  describe "Error handling for missing records" do
    it "handles missing team gracefully" do
      visit team_path(99999)
      
      expect(page).to have_http_status(:not_found)
    end

    it "handles missing player gracefully" do
      visit player_path(99999)
      
      expect(page).to have_http_status(:not_found)
    end

    it "handles missing league gracefully" do
      visit league_path(99999)
      
      expect(page).to have_http_status(:not_found)
    end
  end
end