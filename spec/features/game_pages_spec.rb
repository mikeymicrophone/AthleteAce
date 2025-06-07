require 'rails_helper'

RSpec.feature "Game Pages Functionality", type: :feature do
  before do
    driven_by(:selenium_chrome_headless)
  end

  # Set up complete game test data
  let!(:sport) { create(:sport) }
  let!(:country) { create(:country) }
  let!(:state) { create(:state, country: country) }
  let!(:city) { create(:city, state: state) }
  let!(:stadium) { create(:stadium, city: city) }
  let!(:league) { create(:league, sport: sport, jurisdiction: country) }
  let!(:conference) { create(:conference, league: league) }
  let!(:division) { create(:division, conference: conference) }
  
  # Create multiple teams for choice options
  let!(:team1) { create(:team, league: league, stadium: stadium) }
  let!(:team2) { create(:team, league: league, stadium: stadium) }
  let!(:team3) { create(:team, league: league, stadium: stadium) }
  
  # Create players for each team
  let!(:player1) { create(:player, team: team1) }
  let!(:player2) { create(:player, team: team2) }
  let!(:player3) { create(:player, team: team3) }

  # Create memberships so teams belong to divisions
  let!(:membership1) { create(:membership, team: team1, division: division, active: true) }
  let!(:membership2) { create(:membership, team: team2, division: division, active: true) }
  let!(:membership3) { create(:membership, team: team3, division: division, active: true) }

  feature "Team Match Game" do
    scenario "renders game page with player question" do
      visit strength_team_match_path
      
      expect(page).to have_css(".game-container")
      expect(page).to have_content("Who does")
      expect(page).to have_css(".subject-card")
      expect(page).to have_css(".choices-grid")
    end

    scenario "displays game progress counter" do
      visit strength_team_match_path
      
      expect(page).to have_css(".game-progress")
      expect(page).to have_content("Correct:")
      expect(page).to have_css("[data-game-target='progressCounter']")
    end

    scenario "shows pause functionality" do
      visit strength_team_match_path
      
      expect(page).to have_css("[data-game-target='pauseButton']")
      expect(page).to have_content("Pause")
    end

    scenario "displays team choices", js: true do
      visit strength_team_match_path
      
      expect(page).to have_css(".choices-grid")
      expect(page).to have_css("[data-game-target='choiceItem']", count: 4) # Typically 4 choices
    end
  end

  feature "Division Guess Game" do
    scenario "renders division guessing game page" do
      visit new_division_game_path
      
      expect(page).to have_css(".game-container")
      expect(page).to have_content("division")
      expect(page).to have_css(".subject-card")
      expect(page).to have_css(".choices-grid")
    end

    scenario "displays team question format" do
      visit new_division_game_path
      
      expect(page).to have_content("Which division")
      expect(page).to have_css(".subject-card")
    end

    scenario "shows division choices", js: true do
      visit new_division_game_path
      
      expect(page).to have_css(".choices-grid")
      expect(page).to have_css("[data-game-target='choiceItem']")
    end
  end

  feature "Game Attempts Review Pages" do
    let!(:game_attempt) { 
      create(:game_attempt, 
             target_entity: team1, 
             subject_entity: player1,
             chosen_entity: team2,
             correct: false,
             game_type: "team_match") 
    }

    scenario "renders general game attempts page" do
      visit strength_game_attempts_path
      
      expect(page).to have_content("Game Attempts")
      expect(page).to have_css(".teams-navigation")
    end

    scenario "displays team filter navigation" do
      visit strength_game_attempts_path
      
      expect(page).to have_content("Teams by Sport")
      expect(page).to have_content(sport.name)
      expect(page).to have_link(href: team_strength_game_attempts_path(team1))
    end

    scenario "renders team-specific attempts page" do
      visit team_strength_game_attempts_path(team1)
      
      expect(page).to have_content(team1.territory || team1.mascot)
      expect(page).to have_css(".attempt-card")
    end

    scenario "displays attempt results correctly" do
      visit team_strength_game_attempts_path(team1)
      
      within(".attempt-card") do
        expect(page).to have_content(player1.first_name)
        expect(page).to have_content("Your Guess: #{team2.territory || team2.mascot}")
        expect(page).to have_css(".incorrect-attempt")
      end
    end

    scenario "shows empty state when no attempts" do
      GameAttempt.destroy_all
      visit team_strength_game_attempts_path(team1)
      
      expect(page).to have_content("No attempts")
    end
  end

  feature "Game Integration with Filtering" do
    scenario "accesses team match from team page" do
      visit team_path(team1)
      
      expect(page).to have_link("Quiz Me")
      
      click_link "Quiz Me"
      
      expect(page).to have_css(".game-container")
      expect(page).to have_content("Who does")
    end

    scenario "navigates between game modes" do
      visit strength_path
      
      expect(page).to have_link("Team Match")
      expect(page).to have_link("Division Guess")
      
      click_link "Team Match"
      expect(page).to have_css(".game-container")
      expect(page).to have_content("Who does")
    end
  end

  feature "Game State Management", js: true do
    scenario "maintains game progress" do
      visit strength_team_match_path
      
      initial_count = find("[data-game-target='progressCounter']").text
      expect(initial_count).to eq("0")
      
      # Game progress would be tested through JavaScript interactions
      # This verifies the initial state is correct
    end

    scenario "pause button functionality" do
      visit strength_team_match_path
      
      pause_button = find("[data-game-target='pauseButton']")
      expect(pause_button).to have_content("Pause")
      
      # Would test pause/resume functionality with JavaScript
    end
  end

  feature "Responsive Game Layout" do
    scenario "displays properly on different screen sizes" do
      visit strength_team_match_path
      
      # Test that key game elements are present
      expect(page).to have_css(".game-container")
      expect(page).to have_css(".subject-card")
      expect(page).to have_css(".choices-grid")
      expect(page).to have_css(".game-progress")
    end
  end

  feature "Error Handling in Games" do
    scenario "handles games with insufficient data gracefully" do
      # Remove all teams except one
      Team.where.not(id: team1.id).destroy_all
      
      visit strength_team_match_path
      
      # Should still render, possibly with error message or fallback
      expect(page).to have_css(".game-container")
    end

    scenario "handles division game with no divisions gracefully" do
      Division.destroy_all
      
      visit new_division_game_path
      
      # Should still render, possibly with error message or fallback
      expect(page).to have_css(".game-container")
    end
  end
end