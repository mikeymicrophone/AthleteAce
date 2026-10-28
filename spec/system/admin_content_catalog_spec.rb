require "rails_helper"

RSpec.describe "Admin content catalog workflow", type: :system do
  after { page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride" }

  def viewport(width)
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: width, height: 1000, deviceScaleFactor: 1, mobile: false
  end

  def expect_no_overflow
    expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
  end

  it "filters proposals, edits through the existing form and opens review history on a phone" do
    admin = create :ace, :admin, username: "roster_rae", display_name: "Rae Carter"
    author = create :ace, username: "june_morris", display_name: "June Morris"
    quest = create :quest, name: "Learn the Northern backcourt", description: "Recognize the players who set the pace.", created_by: author
    create :spectrum, name: "Composure", created_by: author
    sign_in admin
    viewport 390
    visit admin_path
    within('[aria-label="Admin navigation mobile"]') { click_link "Content catalog" }
    expect(page).to have_current_path(admin_content_catalog_path)
    expect(page).to have_css('body[data-side="admin"]')
    fill_in "Search content", with: "Northern"
    select "Quests", from: "Content type"
    select "Pending", from: "Status"
    select "June Morris · @june_morris", from: "Creator"
    click_button "Filter content"
    expect(page).to have_content("1 matching record")
    expect(page).to have_css(".content-catalog-table tbody tr", count: 1)
    expect(page).to have_content(quest.name)
    expect_no_overflow
    page.execute_script("document.querySelector('.content-catalog-table').scrollIntoView(); window.scrollBy(0, -90)")
    page.save_screenshot Rails.root.join("tmp/screenshots/content-catalog-phone-light.png")
    within("#content_quest_#{quest.id}") { click_link "Edit" }
    expect(page).to have_current_path(edit_quest_path(quest, side: "admin"))
    within('[aria-label="Admin navigation mobile"]') do
      expect(page).to have_css('a[aria-current="page"]', text: "Content catalog")
    end
    fill_in "Name", with: "Know the Northern backcourt"
    click_button "Update Quest"
    expect(page).to have_content(/Know the Northern backcourt/i)
    expect(quest.reload.name).to eq("Know the Northern backcourt")
    expect(quest.moderation_status).to eq("pending")
    within('[aria-label="Admin navigation mobile"]') { click_link "Content catalog" }
    within("#content_quest_#{quest.id}") { click_link "Review & history" }
    expect(page).to have_current_path(/moderate\/Quest\/#{quest.id}/)
    expect(page).to have_css('body[data-side="mod"]')
    expect(page).to have_content(/Decision history/i)
    expect(page).to have_content("Content changed")
    expect(page).to have_button("Approve")
  end

  it "shows a mixed catalog and an empty result in light and dark on desktop and phone" do
    admin = create :ace, :admin, username: "roster_rae", display_name: "Rae Carter"
    author = create :ace, username: "june_morris", display_name: "June Morris"
    team = create :team, territory: "Oakland", mascot: "Herons"
    create :quest, name: "Learn the Northern backcourt", description: "Recognize the players who set the pace.", created_by: author
    create :achievement, name: "Know the Harbor starting five", description: "Name the players in the current starting group.", target: team
    spectrum = create :spectrum, name: "Composure", description: "Calm decisions when the game is close.", low_label: "Rushed", high_label: "Composed", moderation_status: "hidden"
    sign_in admin
    [ 1440, 390 ].each do |width|
      viewport width
      visit admin_content_catalog_path
      expect(page).to have_css(".content-catalog-table tbody tr", count: 3)
      expect(page).to have_css('a.shell-tab[aria-current="page"]', text: "Content catalog")
      %w[light dark].each do |theme|
        page.execute_script("document.documentElement.dataset.theme = arguments[0]", theme)
        expect_no_overflow
        expect(page).to have_link("Edit", href: edit_spectrum_path(spectrum, side: "admin"))
        page.save_screenshot Rails.root.join("tmp/screenshots/content-catalog-#{width}-#{theme}.png")
      end
    end
    fill_in "Search content", with: "No matching roster"
    click_button "Filter content"
    expect(page).to have_content(/No matching content/i)
    expect(page).to have_link("Clear")
    expect_no_overflow
  end
end
