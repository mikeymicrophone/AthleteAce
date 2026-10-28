require "rails_helper"

RSpec.describe "Shell search palette", type: :system do
  after { page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride" }

  def open_search
    find(".shell-search-toggle").click
    expect(page).to have_css(".shell-search-dialog[open]")
  end

  def phone_viewport
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false
  end

  def expect_no_overflow
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
  end

  it "opens from the keyboard, finds a nickname, follows a result and retains clearable recent searches" do
    player = create(:player, first_name: "Jalen", last_name: "Brunson", nicknames: [ "Big Body" ])
    visit feed_path
    page.driver.browser.action.key_down(:control).send_keys("k").key_up(:control).perform
    expect(page).to have_css(".shell-search-dialog[open]")
    expect(page.evaluate_script("document.activeElement.id")).to eq("shell-search-query")
    fill_in "shell-search-query", with: "Big Body"
    expect(page).to have_css(".search-result", text: "Jalen Brunson")
    page.save_screenshot Rails.root.join("tmp/screenshots/search-desktop.png")
    find("#shell-search-query").send_keys(:arrow_down)
    expect(page).to have_css('.search-result[aria-selected="true"]', text: "Jalen Brunson")
    find("#shell-search-query").send_keys(:enter)
    expect(page).to have_current_path(player_path(player, side: "feed"))
    expect(page).to have_css('body[data-side="feed"]')
    open_search
    within(".search-recents") { expect(page).to have_button("Big Body") }
    click_button "Big Body"
    expect(page).to have_css(".search-result", text: "Jalen Brunson")
    find("#shell-search-query").send_keys(:escape)
    expect(page).not_to have_css(".shell-search-dialog[open]")
    expect(page.evaluate_script("document.activeElement.classList.contains('shell-search-toggle')")).to be(true)
    open_search
    fill_in "shell-search-query", with: ""
    click_button "Clear recent searches"
    expect(page).not_to have_button("Big Body")
  end

  it "fits visitor and fan navigation on mobile and wraps arrow selection in light and dark" do
    ace = create(:ace)
    knicks = create(:team, territory: "New York", mascot: "Knicks", abbreviation: "NYK")
    create(:team, territory: "New York", mascot: "Nets", abbreviation: "NYN", league: knicks.league)
    visit feed_path
    phone_viewport
    expect_no_overflow
    open_search
    expect_no_overflow
    find("#shell-search-query").send_keys(:escape)
    sign_in ace
    visit strength_path
    open_search
    fill_in "shell-search-query", with: "New York"
    expect(page).to have_css(".search-result", count: 2)
    find("#shell-search-query").send_keys(:arrow_up)
    expect(page).to have_css('.search-result[aria-selected="true"]', text: "New York Nets")
    find("#shell-search-query").send_keys(:arrow_down)
    expect(page).to have_css('.search-result[aria-selected="true"]', text: "New York Knicks")
    expect_no_overflow
    page.save_screenshot Rails.root.join("tmp/screenshots/search-mobile-light.png")
    find("#shell-search-query").send_keys(:escape)
    find('[aria-label="Account menu"]').click
    within("dialog[open]") { click_button "Dark" }
    open_search
    fill_in "shell-search-query", with: "New York"
    expect(page).to have_css(".search-result", count: 2)
    expect(page).to have_css('html[data-theme="dark"]')
    expect_no_overflow
    page.save_screenshot Rails.root.join("tmp/screenshots/search-mobile-dark.png")
    find("#shell-search-query").send_keys(:arrow_down, :enter)
    expect(page).to have_current_path(team_path(knicks, side: "play"))
  end

  it "uses the moderator scope and opens a submitted item for review" do
    author = create(:ace, username: "clutch_sam", display_name: "Sam Carter")
    reviewer = create(:ace, moderator: true)
    quest = create(:quest, created_by: author, name: "Clutch starting five")
    sign_in reviewer
    visit moderation_path
    open_search
    fill_in "shell-search-query", with: "clutch"
    expect(page).to have_css('[aria-label="Queue"]', text: "Clutch starting five")
    expect(page).to have_css('[aria-label="Aces"]', text: "@clutch_sam")
    within(".shell-search-dialog") { click_link "Clutch starting five" }
    expect(page).to have_current_path(moderation_item_path(type: "Quest", id: quest.id))
    expect(page).to have_button("Approve")
  end
end
