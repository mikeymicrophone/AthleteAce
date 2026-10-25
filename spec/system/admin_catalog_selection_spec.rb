require "rails_helper"

RSpec.describe "Admin catalog row selection", type: :system do
  after { page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride" }

  it "selects only the displayed filtered page, supports individual changes and resets on navigation" do
    admin = create(:ace, :admin, theme: "light")
    league = create(:league, name: "Harbor Basketball League", sport: create(:sport, name: "Basketball"))
    team = create(:team, territory: "Harbor", mascot: "Herons", league: league)
    names = %w[Jordan_Reed Morgan_Price Avery_Cole Casey_Brooks Taylor_Ellis Cameron_Grant Riley_Hayes Alex_James Drew_King Quinn_Lane Parker_Miles Jamie_Nash Rowan_Owens Sage_Perry Reese_Quinn Finley_Ross Logan_Shaw Emerson_Tate Dakota_Vaughn Hayden_Ward Charlie_Young Blake_Zhang Micah_Adams Elliot_Bennett Jesse_Carter Noel_Davis]
    players = names.map do |name|
      first_name, last_name = name.split("_")
      create(:player, first_name: first_name, last_name: last_name, team: team)
    end
    create(:player, first_name: "Unrelated", last_name: "Athlete")
    sign_in admin
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false
    visit admin_catalog_records_path(team_id: team.id, number_on: "2024-06-30")
    expect(page).to have_button("Export selected CSV", disabled: true)
    expect(page).to have_css('[data-catalog-selection-target="item"]', count: 25)
    check "select_record_#{players.first.id}"
    expect(page).to have_content("1 selected")
    expect(page).to have_button("Export selected CSV", disabled: false)
    expect(page.evaluate_script('document.querySelector("[data-catalog-selection-target=all]").indeterminate')).to be(true)
    check "Select page"
    expect(page).to have_content("25 selected")
    uncheck "select_record_#{players.first.id}"
    expect(page).to have_content("24 selected")
    form = find('form[data-controller="catalog-selection"]')
    expect(form[:action]).to end_with(admin_catalog_records_path(format: :csv))
    expect(form[:"data-turbo"]).to eq("false")
    fields = page.evaluate_script('Object.fromEntries(new FormData(document.querySelector("form[data-controller=catalog-selection]")))')
    expect(fields).to include("selection" => "selected", "team_id" => team.id.to_s, "kind" => "players", "number_on" => "2024-06-30")
    expect(page.evaluate_script('new FormData(document.querySelector("form[data-controller=catalog-selection]")).getAll("selected_ids[]").length')).to eq(24)
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    page.execute_script("arguments[0].scrollIntoView({block: 'center'})", find('[data-catalog-selection-target="count"]'))
    page.save_screenshot Rails.root.join("tmp/screenshots/admin-catalog-selection-mobile.png")
    visit admin_catalog_records_path(team_id: team.id, number_on: "2024-06-30", page: 2)
    expect(page).to have_css('[data-catalog-selection-target="item"]', count: 1)
    expect(page).to have_content("0 selected")
    check "Select page"
    expect(page).to have_content("1 selected")
    visit admin_catalog_records_path(kind: "teams", q: "Herons")
    expect(page).to have_content("0 selected")
    check "select_record_#{team.id}"
    expect(page).to have_content("1 selected")
    page.execute_script("document.documentElement.dataset.theme = 'dark'")
    page.execute_script("arguments[0].scrollIntoView({block: 'center'})", find('[data-catalog-selection-target="count"]'))
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    page.save_screenshot Rails.root.join("tmp/screenshots/admin-team-selection-dark.png")
  end
end
