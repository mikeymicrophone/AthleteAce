require "rails_helper"

RSpec.describe "Group practice from Play home", type: :system do
  it "shows current progress and completes remaining practice from the home card on mobile" do
    ace = create(:ace)
    team = create(:team)
    rival = create(:team, league: team.league)
    jalen = create(:player, first_name: "Jalen", last_name: "Brunson", team: team)
    josh = create(:player, first_name: "Josh", last_name: "Hart", team: rival, active: false)
    group = PlayerGroup.create!(name: "Knicks names", players: [ jalen, josh ])
    round = GameRoundSetup.new(game_type: "name_ciphers", player_group_id: group.id).start!(ace)
    round.answer!(at: 0, choice_id: round.question.fetch("target_id"))
    round.advance!(at: 0)
    round.answer!(at: 1, choice_id: nil)
    round.advance!(at: 1)
    sign_in ace
    visit strength_path
    expect(page).to have_css(".play-groups .group-practice-card", count: 1)
    within(".play-groups") do
      expect(page).to have_content("1 of 2")
      expect(page).to have_link("Practice misses")
    end
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false
    expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
    page.scroll_to find("#play-groups-title"), align: :top
    page.save_screenshot Rails.root.join("tmp/screenshots/play-group-overview-mobile.png")
    page.execute_script("document.documentElement.dataset.theme = 'light'")
    page.save_screenshot Rails.root.join("tmp/screenshots/play-group-overview-mobile-light.png")
    within(".play-groups") { click_link "Practice remaining 1" }
    expect(page).to have_select("Members to practice", selected: "Not yet answered correctly")
    click_button "Start round"
    expect(page).to have_css(".round-game-progress", text: "1 / 1")
    current = ace.game_rounds.last
    find(".round-choice[value='#{current.question.fetch('target_id')}']").click
    expect(page).to have_css(".round-feedback", text: /Correct/i)
    click_button "Round summary"
    visit strength_path
    within(".play-groups") do
      expect(page).to have_content("2 of 2")
      expect(page).to have_link("Practice group")
      expect(page).not_to have_link("Practice misses")
      click_link "All groups"
    end
    expect(page).to have_css(".group-practice-card", count: 1)
    expect(page).to have_content("2 of 2")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
  ensure
    page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride"
  end
end
