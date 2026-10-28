require "rails_helper"

RSpec.describe "Admin game directory", type: :system do
  after { page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride" }

  it "filters games and inspects appearances and explicit availability on mobile" do
    admin = create(:ace, :admin, theme: "light")
    league = create(:nba)
    season = create(:season, league: league, year: create(:year, number: 2024))
    team = create(:team, league: league, territory: "Harbor", mascot: "Herons")
    campaign = Campaign.create!(team: team, season: season)
    game = Game.create!(context: league, name: "Herons vs Foxes", begin_date: Date.new(2024, 11, 2), entity_code: "HBL:GAME:001")
    entry = Contestant.create!(contest: game, campaign: campaign)
    player = create(:player, first_name: "Jordan", last_name: "Reed", sport: league.sport, team: nil)
    Appearance.create!(contestant: entry, player: player, jersey_number: "00", starter: nil, statistics: { points: 18, minutes: 34 })
    roster = Roster.create!(campaign: campaign, kind: "game_availability", coverage: "complete", effective_on: game.begin_date, details: { game_code: game.entity_code })
    RosterEntry.create!(roster: roster, player: player, status: "active", jersey_number: "00")
    sign_in admin
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false
    visit admin_catalog_records_path
    click_link "Games", exact: true
    fill_in "Search games", with: "HBL:GAME:001"
    select "Recorded appearances", from: "Appearances"
    click_button "Filter games"
    expect(page).to have_content("1 matching game")
    expect(page).to have_link(game.name, href: admin_game_path(game))
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    page.save_screenshot Rails.root.join("tmp/screenshots/admin-games-mobile.png")
    click_link game.name
    expect(page).to have_content("Jordan Reed")
    expect(page).to have_content('"points":18')
    expect(page).to have_content("Unknown")
    click_link "Roster entries", exact: true
    expect(page).to have_content("Coverage: complete")
    expect(page).to have_content("Jordan Reed")
    expect(page).to have_content("active")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    page.execute_script("document.documentElement.dataset.theme = 'dark'")
    page.save_screenshot Rails.root.join("tmp/screenshots/admin-game-roster-dark.png")
    click_link "Appearances", exact: true
    expect(page).to have_content('"points":18')
    expect(page).to have_no_content("Coverage: complete")
  end
end
