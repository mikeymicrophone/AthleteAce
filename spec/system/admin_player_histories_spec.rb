require "rails_helper"

RSpec.describe "Admin player history navigation", type: :system do
  after { page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride" }

  it "traces a player's organization contract, assignment, availability and appearance on mobile" do
    admin = create(:ace, :admin, theme: "light")
    sport = create(:sport, name: "Basketball")
    league = create(:league, sport: sport, name: "Harbor Basketball League")
    team = create(:team, territory: "Harbor", mascot: "Herons", league: league)
    player = create(:player, first_name: "Jordan", last_name: "Reed", team: nil, sport: sport)
    season = create(:season, league: league, year: create(:year, number: 2024))
    campaign = Campaign.create!(team: team, season: season)
    organization = create(:organization, name: "Harbor Basketball Club")
    contract = Contract.create!(player: player, organization: organization, start_date: Date.new(2024, 10, 1))
    event = Transaction.create!(kind: "assignment", effective_on: Date.new(2024, 10, 2))
    TransactionPlayer.create!(event: event, player: player, to_team: team, to_organization: organization)
    Stint.create!(player: player, team: team, contract: contract, start_transaction: event, start_date: Date.new(2024, 10, 2))
    roster = Roster.create!(campaign: campaign, kind: "game_availability", coverage: "partial", effective_on: Date.new(2024, 11, 2))
    RosterEntry.create!(roster: roster, player: player, status: "active", jersey_number: "00")
    game = Game.create!(context: league, name: "Herons vs Foxes", begin_date: Date.new(2024, 11, 2))
    contestant = Contestant.create!(contest: game, campaign: campaign)
    Appearance.create!(contestant: contestant, player: player, starter: false, statistics: { points: 0 })
    sign_in admin
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false
    visit edit_admin_catalog_record_path(player, kind: "players")
    click_link "Player history", exact: true
    expect(page).to have_content("Current profile team: Unassigned")
    expect(page).to have_content("Harbor Basketball Club")
    expect(page).to have_content("Harbor Herons")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    page.save_screenshot Rails.root.join("tmp/screenshots/admin-player-history-mobile.png")
    click_link "Contracts (1)", exact: true
    expect(page).to have_content("Organization contracts do not establish a team assignment")
    expect(page).to have_content("2024-10-01")
    click_link "Transactions (1)", exact: true
    expect(page).to have_content("day resolution")
    expect(page).to have_content("2024-10-02")
    click_link "Rosters (1)", exact: true
    expect(page).to have_content("partial")
    expect(page).to have_content("00")
    click_link "Appearances (1)", exact: true
    expect(page).to have_link(game.name, href: admin_game_path(game))
    expect(page).to have_content('"points":0')
    page.execute_script("document.documentElement.dataset.theme = 'dark'")
    page.execute_script("arguments[0].scrollIntoView({block: 'center'})", find("table"))
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    page.save_screenshot Rails.root.join("tmp/screenshots/admin-player-appearances-dark.png")
    click_link game.name
    click_link player.name
    expect(page).to have_current_path(admin_player_history_path(player))
    click_link "Edit profile data", exact: true
    expect(page).to have_current_path(edit_admin_catalog_record_path(player, kind: "players"))
  end
end
