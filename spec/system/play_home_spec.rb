require "rails_helper"

RSpec.describe "Play home and quest browsing", type: :system do
  let(:ace) { create(:ace) }
  let(:team) { create(:team, territory: "Green Bay", mascot: "Packers", abbreviation: "GB") }
  let(:quest) { create(:quest, name: "NFC North Roll Call", description: "Know the teams and the players who make them go.") }

  before do
    driven_by :selenium_chrome_headless
    create(:team, league: team.league)
    create(:player, team: team)
    achievement = create(:achievement, name: "Learn the Packers roster", target: team)
    create(:highlight, quest: quest, achievement: achievement)
    create(:goal, ace: ace, quest: quest, status: "in_progress")
    sign_in ace
  end

  after { page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride" }

  def no_overflow
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
  end

  it "starts and resumes a round, then explores quests on desktop and mobile" do
    visit strength_path
    expect(page).to have_content(/Make names stick\./i)
    expect(page).to have_content("NFC North Roll Call")
    no_overflow
    page.save_screenshot Rails.root.join("tmp/screenshots/play-home-desktop.png")
    click_button "Quick round"
    expect(page).to have_css(".round-game-progress", text: "1 / 10")
    click_button "Pause round"
    visit strength_path
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false
    expect(page).to have_content("0 of 10 answered")
    no_overflow
    page.save_screenshot Rails.root.join("tmp/screenshots/play-home-mobile.png")
    within(".round-continue") { click_link "Continue" }
    expect(page).to have_button("Resume round")
    visit quests_path
    expect(page).to have_css(".quest-card", count: 1)
    no_overflow
    page.save_screenshot Rails.root.join("tmp/screenshots/quests-mobile.png")
    click_link "View quest"
    expect(page).to have_content(/Your goal/i)
    no_overflow
    page.save_screenshot Rails.root.join("tmp/screenshots/quest-detail-mobile.png")
    page.execute_script("document.documentElement.dataset.theme = 'dark'")
    page.save_screenshot Rails.root.join("tmp/screenshots/quest-detail-dark.png")
    click_link "Practice"
    expect(page).to have_content(team.name)
    expect(page).to have_button("Start round")
  end
end
