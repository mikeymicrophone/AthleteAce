require "rails_helper"

RSpec.describe "Following from entity pages", type: :system do
  it "updates buttons in place and uses a followed team for a Quick round on mobile" do
    ace = create(:ace)
    team = create(:team, territory: "New York", mascot: "Knicks", abbreviation: "NYK")
    rival = create(:team, league: team.league)
    player = create(:player, team: team, first_name: "Jalen", last_name: "Brunson")
    create(:player, team: rival)
    sign_in ace
    visit team_path(team)
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false
    within("#follow_team_#{team.id}") do
      click_button "Follow"
      expect(page).to have_button("Following")
    end
    expect(page).to have_current_path(team_path(team))
    expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
    visit player_path(player)
    within("#follow_player_#{player.id}") do
      click_button "Follow"
      expect(page).to have_button("Following")
      click_button "Following"
      expect(page).to have_button("Follow", exact: true)
      click_button "Follow"
      expect(page).to have_button("Following")
    end
    visit profile_path
    expect(page).to have_css("#profile-following-title", text: /Following/i)
    expect(page).to have_content(player.name)
    expect(page).to have_content(team.name)
    page.execute_script("document.documentElement.dataset.theme = 'dark'")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
    page.execute_script("document.querySelector('#profile-following-title').scrollIntoView()")
    page.save_screenshot Rails.root.join("tmp/screenshots/following-profile-mobile.png")
    within("#follow_#{ace.follows.find_by!(followable: player).id}") { click_button "Following" }
    expect(page).not_to have_link(player.name)
    expect(ace.follows.where(followable: player)).to be_empty
    visit strength_path
    click_button "Quick round"
    expect(page).to have_css(".round-game-progress", text: "1 / 1")
    expect(ace.game_rounds.last.question.fetch("subject_id")).to eq(player.id)
  ensure
    page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride"
  end
end
