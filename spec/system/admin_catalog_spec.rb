require "rails_helper"

RSpec.describe "Admin sports data workflow", type: :system do
  it "saves first, leaves a reason missing, then explains that exact edit on mobile" do
    admin = create(:ace, :admin, username: "roster_rae", display_name: "Rae Carter", theme: "light")
    team = create(:team, territory: "New York", mascot: "Knicks", abbreviation: "NYK", primary_color: "#006BB6", secondary_color: "#F58426")
    player = create(:player, first_name: "Jalen", last_name: "Brunson", entity_code: "AA:PLAYER:BRUNSON", team: team, current_position: "PG", active: true)
    sign_in admin
    visit admin_catalog_records_path
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false
    fill_in "Search players", with: "Jalen"
    click_button "Filter sports data"
    expect(page).to have_current_path(/q=Jalen/)
    expect(page).to have_content("Jalen Brunson")
    export = find_link("Export filtered CSV")
    expect(URI.parse(export[:href]).path).to eq(admin_catalog_records_path(format: :csv))
    expect(Rack::Utils.parse_query(URI.parse(export[:href]).query)).to include("q" => "Jalen", "kind" => "players")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    save_screenshot("/tmp/screenshots/catalog-players-mobile.png")
    click_link "Jalen Brunson"
    fill_in "First name", with: "Jalen Marquis"
    click_button "Save changes"
    expect(page).to have_content("Saved. Why did you make this change?")
    expect(player.reload.first_name).to eq("Jalen Marquis")
    first = CatalogEdit.sole
    expect(page).to have_content("Before")
    expect(page).to have_content("After")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    save_screenshot("/tmp/screenshots/catalog-reason-mobile.png")
    click_link "Skip for now"
    expect(first.reload.reason).to be_nil
    click_link "Correction history"
    expect(page).to have_content("Reason not supplied")
    click_link "Jalen Brunson · Edit ##{first.id}"
    expect(page).to have_current_path(admin_catalog_edit_path(first))
    expect(page).to have_no_css("html[data-turbo-preview]")
    fill_in "Why did you make this change?", with: "The roster gives his full first name."
    click_button "Save reason"
    expect(page).to have_content("Reason saved.")
    expect(first.reload.reason).to eq("The roster gives his full first name.")
    visit admin_catalog_records_path(kind: "teams")
    click_link "New York Knicks"
    fill_in "Primary color", with: "#FFFFFF"
    click_button "Save changes"
    expect(page).to have_content("Text color")
    expect(page).to have_content(TeamPalette::DARK_TEXT)
    page.execute_script("document.documentElement.dataset.theme = 'dark'")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    save_screenshot("/tmp/screenshots/catalog-team-dark.png")
  ensure
    page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride"
  end
end
