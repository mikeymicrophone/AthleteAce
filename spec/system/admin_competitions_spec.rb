require "rails_helper"

RSpec.describe "Admin competition directory", type: :system do
  after { page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride" }

  it "inspects a cross-league cup, its awards and linked game on mobile" do
    admin = create(:ace, :admin, theme: "light")
    league = create(:league, name: "Harbor Basketball League", sport: create(:sport, name: "Basketball"))
    other_league = create(:league, name: "Coastal Basketball League", sport: league.sport)
    year = create(:year, number: 2024)
    season = create(:season, league: league, year: year)
    other_season = create(:season, league: other_league, year: year)
    team = create(:team, territory: "Harbor", mascot: "Herons", league: league)
    other = create(:team, territory: "Coastal", mascot: "Foxes", league: other_league)
    campaign = Campaign.create!(team: team, season: season)
    other_campaign = Campaign.create!(team: other, season: other_season)
    cup = Contest.create!(context: league.sport, kind: "cup", name: "Harbor Invitational Cup", begin_date: Date.new(2024, 10, 20), end_date: Date.new(2024, 11, 2), entity_code: "BASKETBALL:CUP:HARBOR:2024", format_rules: { rounds: [ { key: "final", name: "Final", best_of: 3 } ], qualification: "Invited clubs" })
    entrant = Contestant.create!(contest: cup, campaign: campaign)
    Contestant.create!(contest: cup, campaign: other_campaign)
    TitleAward.create!(contest: cup, winner: entrant, key: "cup", name: "Invitational champions", awarded_on: Date.new(2024, 11, 2))
    game = Game.create!(context: league.sport, name: "Herons vs Foxes", begin_date: Date.new(2024, 11, 2))
    Contestant.create!(contest: game, campaign: campaign)
    Contestant.create!(contest: game, campaign: other_campaign)
    ContestGame.create!(contest: cup, game: game, metadata: { round: "final", game_number: 1 })
    sign_in admin
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false
    visit admin_catalog_records_path
    click_link "Competitions", exact: true
    fill_in "Search competitions", with: "HARBOR:2024"
    select "Recorded awards", from: "Titles"
    click_button "Filter competitions"
    expect(page).to have_content("1 matching competition")
    click_link cup.name
    expect(page).to have_content("2 recorded entrants")
    expect(page).to have_content("Assigned season: Not set")
    expect(page).to have_content("Best of 3")
    expect(page).to have_content(season.name)
    expect(page).to have_content(other_season.name)
    find("summary", text: "All recorded rules").click
    expect(page).to have_content("Invited clubs")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    page.save_screenshot Rails.root.join("tmp/screenshots/admin-competition-mobile.png")
    click_link "Title awards", exact: true
    expect(page).to have_content("Invitational champions")
    expect(page).to have_content("Harbor Herons")
    page.execute_script("document.documentElement.dataset.theme = 'dark'")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    page.execute_script("arguments[0].scrollIntoView({block: 'center'})", find("table"))
    page.save_screenshot Rails.root.join("tmp/screenshots/admin-competition-titles-dark.png")
    click_link "View games", exact: true
    expect(page).to have_select("Competition", selected: cup.name)
    expect(page).to have_link(game.name)
    click_link game.name
    expect(page).to have_content("Final · Game 1")
    click_link cup.name
    expect(page).to have_current_path(admin_competition_path(cup))
  end
end
