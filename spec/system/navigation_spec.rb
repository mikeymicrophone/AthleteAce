require "rails_helper"

RSpec.describe "Navigation", type: :system do
  after { page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride" }

  def phone_viewport
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false
  end

  def expect_no_overflow
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
  end

  def open_menu(label = "Account menu")
    expect(page).to have_css('[data-controller~="shell"]') {
      page.evaluate_script("!document.documentElement.hasAttribute('data-turbo-preview') && Boolean(window.Stimulus?.getControllerForElementAndIdentifier(document.querySelector('[data-controller~=shell]'), 'shell'))")
    }
    find("button[aria-label='#{label}']").click
    expect(page).to have_css("dialog[open]")
  end

  it "opens Feed for visitors and offers Play preview and sign-in" do
    visit root_path
    expect(page).to have_current_path(feed_path)
    within('[aria-label="Switch sides"]') do
      expect(page).to have_link("Play")
      expect(page).to have_link("Feed")
      expect(page).not_to have_link("Moderate")
      expect(page).not_to have_link("Admin")
      expect(page).to have_content(/preview/i)
    end
    expect(page).to have_link("Sign In")
    expect(page).not_to have_link("Sign Up")
    within('[aria-label="Switch sides"]') { click_link "Play" }
    expect(page).to have_current_path(strength_path)
    within('[aria-label="Play navigation"]') { click_link "Browse" }
    expect(page).to have_css("h1", text: /browse/i)
    within("#browse-sports") do
      expect(page).to have_link("Sports")
      click_link "Teams"
    end
    expect(page).to have_current_path(teams_path)
    expect(page).to have_css('body[data-side="play"]')
  end

  it "saves a visitor's appearance without an account" do
    phone_viewport
    visit feed_path
    open_menu "Appearance"
    expect(page).to have_css("dialog[open]")
    within("dialog[open]") { click_button "Dark" }
    expect(page).to have_css('html[data-theme="dark"]')
    page.refresh
    expect(page).to have_css('html[data-theme="dark"]')
    open_menu "Appearance"
    within("dialog[open]") { click_button "System" }
    expect(page).to have_css('html[data-theme="system"]')
    expect_no_overflow
  end

  it "keeps five mobile Play tabs and an accessible account sheet with saved themes and sign-out" do
    ace = create(:ace, email: "tess.moreno@example.test")
    sign_in ace
    phone_viewport
    visit root_path
    expect(page).to have_current_path(strength_path)
    within('[aria-label="Play navigation mobile"]') do
      expect(all("a").map(&:text)).to eq(%w[Home Games Quests History Browse])
      all("a").each { |link| expect(link.native.rect.height).to be >= 44 }
    end
    expect_no_overflow
    open_menu
    expect(page).to have_css("dialog[open]", text: ace.handle)
    page.save_screenshot Rails.root.join("tmp/screenshots/shell-account-mobile.png")
    page.driver.browser.action.send_keys(:escape).perform
    expect(page).not_to have_css("dialog[open]")
    expect(page.evaluate_script("document.activeElement.getAttribute('aria-label')")).to eq("Account menu")
    open_menu
    within("dialog[open]") do
      expect(page).to have_link("My ratings")
      expect(page).to have_link("Settings")
      expect(page).to have_link("Begin Quest")
      click_button "Dark"
    end
    expect(page).to have_css('html[data-theme="dark"]')
    expect(ace.reload.theme).to eq("dark")
    within('[aria-label="Play navigation mobile"]') { click_link "Browse" }
    expect(page).to have_css('html[data-theme="dark"]')
    expect_no_overflow
    open_menu
    within("dialog[open]") { click_button "Sign Out" }
    expect(page).to have_link("Sign In")
    expect(page).to have_current_path(feed_path)
    expect(page).to have_css('html[data-theme="system"]')
  end

  it "keeps the moderation side on shared pages and exposes its mobile queue and log" do
    reviewer = create(:ace, moderator: true, email: "sam.carter@example.test")
    player = create(:player, first_name: "Jalen", last_name: "Brunson")
    create(:quest, created_by: create(:ace), name: "Learn the Knicks starting five")
    sign_in reviewer
    visit moderation_path
    expect(page).to have_css(".shell-sidebar", visible: true)
    page.save_screenshot Rails.root.join("tmp/screenshots/shell-moderate-desktop.png")
    visit player_path(player)
    expect(page).to have_css('body[data-side="mod"]')
    within('[aria-label="Switch sides"]') { click_link "Play" }
    expect(page).to have_current_path(strength_path)
    visit player_path(player)
    expect(page).to have_css('body[data-side="play"]')
    phone_viewport
    within('[aria-label="Switch sides"]') { click_link "Moderate" }
    within('[aria-label="Moderate navigation mobile"]') { click_link "Decision log" }
    expect(page).to have_current_path(moderation_log_path)
    expect_no_overflow
    page.save_screenshot Rails.root.join("tmp/screenshots/shell-moderate-mobile.png")
    expect(page).not_to have_css(".shell-sidebar", visible: true)
  end

  it "provides admin catalog navigation and remembers the Admin side" do
    sign_in create(:ace, :admin, email: "alex.rivera@example.test")
    visit root_path
    expect(page).to have_current_path(admin_path)
    within('[aria-label="Switch sides"]') { expect(all("a").size).to eq(4) }
    within(".shell-sidebar") { click_link "Sports data" }
    within("#browse-sports") { click_link "Teams" }
    expect(page).to have_css('body[data-side="admin"]')
    phone_viewport
    expect_no_overflow
    within('[aria-label="Admin navigation mobile"]') { click_link "Content catalog" }
    expect(page).to have_content(/quests and ratings/i)
    expect(page).to have_css('body[data-side="admin"]')
    page.save_screenshot Rails.root.join("tmp/screenshots/shell-admin-mobile.png")
  end

  it "keeps quest discovery reachable through the account menu" do
    sign_in create(:ace)
    create_list(:quest, 3)
    visit root_path
    open_menu
    within("dialog[open]") { click_link "Begin Quest" }
    expect(page).to have_content("Quest Discovery")
    expect(page).to have_button("Begin Quest")
    expect(page).to have_link("Next Quest")
    expect(page).not_to have_css("dialog[open]")
  end
end
