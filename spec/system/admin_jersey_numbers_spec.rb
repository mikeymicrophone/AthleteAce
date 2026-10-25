require "rails_helper"

RSpec.describe "Admin dated jersey workflow", type: :system do
  after { page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride" }

  it "selects a date and follows a string number to assignment history on mobile" do
    admin = create(:ace, :admin, theme: "light")
    team = create(:team, territory: "Harbor", mascot: "Herons")
    player = create(:player, first_name: "Jordan", last_name: "Reed", team: team)
    JerseyNumberAssignment.create!(player: player, team: team, number: "00", start_date: Date.new(2024, 1, 1), end_date: Date.new(2024, 6, 30), entity_code: "HBL:NUMBER:REED:00")
    JerseyNumberAssignment.create!(player: player, team: team, number: "7", start_date: Date.new(2024, 7, 1))
    sign_in admin
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false
    visit admin_catalog_records_path(q: "Jordan", number_on: "2024-06-30")
    expect(page).to have_field("Number on date", with: "2024-06-30")
    expect(page).to have_link("00", href: admin_player_history_path(player, tab: "numbers"))
    export = find_link("Export filtered CSV")
    expect(Rack::Utils.parse_query(URI.parse(export[:href]).query)["number_on"]).to eq("2024-06-30")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    page.save_screenshot Rails.root.join("tmp/screenshots/admin-number-date-mobile.png")
    click_link "00", exact: true
    expect(page).to have_content("Number assignments (2)")
    expect(page).to have_content("HBL:NUMBER:REED:00")
    expect(page).to have_content("Open end")
    expect(page).to have_content("2024-06-30")
    page.execute_script("document.documentElement.dataset.theme = 'dark'")
    page.execute_script("arguments[0].scrollIntoView({block: 'center'})", find("table"))
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    page.save_screenshot Rails.root.join("tmp/screenshots/admin-number-history-dark.png")
  end
end
