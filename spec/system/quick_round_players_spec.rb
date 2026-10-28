require "rails_helper"

RSpec.describe "Quick practice for followed players", type: :system do
  it "follows unassigned retired players, plays their names and retains them on replay on mobile" do
    ace = create(:ace)
    tim = create(:player, first_name: "Tim", last_name: "Duncan", team: nil, active: false)
    manu = create(:player, first_name: "Manu", last_name: "Ginobili", team: nil, active: false)
    sign_in ace
    [ tim, manu ].each do |player|
      visit player_path(player)
      within("#follow_player_#{player.id}") do
        click_button "Follow"
        expect(page).to have_button("Following")
      end
    end
    visit strength_path
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false
    click_button "Quick round"
    expect(page).to have_css(".round-game-progress", text: "1 / 2")
    round = ace.game_rounds.last
    expect(round.game_type).to eq("name_ciphers")
    expect(round.questions.map { |q| q.fetch("subject_id") }).to match_array([ tim.id, manu.id ])
    round.questions.each_with_index do |question, position|
      expect(page).to have_css(".round-game-progress", text: "#{position + 1} / 2")
      find(".round-choice[value='#{question.fetch('target_id')}']").click
      expect(page).to have_css(".round-feedback", text: /Correct/i)
      click_button(position == 1 ? "Round summary" : "Next")
    end
    expect(page).to have_css(".round-final-score", text: "2 / 2")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
    page.execute_script("document.documentElement.dataset.theme = 'dark'")
    page.save_screenshot Rails.root.join("tmp/screenshots/followed-players-quick-summary-mobile.png")
    click_link "Play again"
    expect(page).to have_content("2 players available")
    expect(page).to have_content("Tim Duncan")
    expect(page).to have_content("Manu Ginobili")
    expect(page).to have_checked_field("Name Ciphers")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
  ensure
    page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride"
  end
end
