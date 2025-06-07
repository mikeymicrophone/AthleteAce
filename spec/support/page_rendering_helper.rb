# Helper methods for page rendering tests
module PageRenderingHelper
  # Helper to create a complete data hierarchy for testing
  def create_complete_test_data
    sport = create(:sport)
    country = create(:country)
    state = create(:state, country: country)
    city = create(:city, state: state)
    stadium = create(:stadium, city: city)
    league = create(:league, sport: sport, jurisdiction: country)
    conference = create(:conference, league: league)
    division = create(:division, conference: conference)
    team = create(:team, league: league, stadium: stadium)
    player = create(:player, team: team)
    quest = create(:quest)
    spectrum = create(:spectrum)
    achievement = create(:achievement)
    
    # Create membership to link team to division
    create(:membership, team: team, division: division, active: true)
    
    {
      sport: sport,
      country: country,
      state: state,
      city: city,
      stadium: stadium,
      league: league,
      conference: conference,
      division: division,
      team: team,
      player: player,
      quest: quest,
      spectrum: spectrum,
      achievement: achievement
    }
  end

  # Verify that a page contains expected navigation elements
  def expect_standard_navigation
    expect(page).to have_css(".navigation-container")
  end

  # Verify that a page contains expected index structure
  def expect_index_structure
    expect(page).to have_css(".index-collection")
  end

  # Verify that a filterable page shows filter context
  def expect_filter_context(filter_names)
    Array(filter_names).each do |name|
      expect(page).to have_content(name)
    end
  end

  # Check that game pages have required elements
  def expect_game_structure
    expect(page).to have_css(".game-container")
    expect(page).to have_css(".subject-card")
    expect(page).to have_css(".choices-grid")
  end

  # Verify error pages render appropriately
  def expect_error_handling(status_code)
    expect(page).to have_http_status(status_code)
  end
end

RSpec.configure do |config|
  config.include PageRenderingHelper, type: :system
  config.include PageRenderingHelper, type: :feature
end