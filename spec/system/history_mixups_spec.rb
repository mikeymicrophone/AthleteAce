require "rails_helper"

RSpec.describe "Practice player mix-ups", type: :system do
  it "opens a focused pair from history and keeps it while switching modes on mobile" do
    ace = create(:ace)
    jalen = create(:player, first_name: "Jalen", last_name: "Brunson", team: nil, active: false, photo_urls: [ "/icon.png" ])
    josh = create(:player, first_name: "Josh", last_name: "Hart", team: nil, photo_urls: [ "/icon.png" ])
    create(:player, first_name: "Mikal", last_name: "Bridges")
    ids = [ jalen.id, josh.id ]
    round = GameRoundSetup.new(game_type: "name_ciphers", player_ids: ids, include_inactive: true).start!(ace)
    wrong = (ids - [ round.question.fetch("target_id") ]).sole
    round.answer!(at: 0, choice_id: wrong)
    sign_in ace
    visit strength_game_attempts_path
    expect(page).to have_content(/Players you mix up/i)
    expect(page).to have_content("1 mix-up")
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false
    expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
    page.scroll_to find("#history-player-mixups-title"), align: :top
    page.save_screenshot Rails.root.join("tmp/screenshots/history-player-mixups-mobile.png")
    click_link "Drill names"
    expect(page).to have_content("Focused players · Jalen Brunson · Josh Hart")
    choose "Image Recognition"
    expect(page).to have_checked_field("Image Recognition")
    expect(page).to have_css(".round-start-dock", text: "Image Recognition")
    expect(page).to have_content("2 players available")
    click_button "Start round"
    expect(page).to have_css(".round-game-progress", text: "1 / 2")
    saved = ace.game_rounds.last
    expect(saved.game_type).to eq("image_recognition")
    expect(saved.questions.map { |question| question.fetch("subject_id") }).to match_array(ids)
    expect(all(".round-choice").map(&:text).join).not_to include("Mikal")
    find(".round-choice[value='#{saved.question.fetch('target_id')}']").click
    expect(page).to have_css(".round-feedback", text: /Correct/i)
    page.execute_script("document.documentElement.dataset.theme = 'dark'")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
    click_button "Next"
    expect(page).to have_css(".round-game-progress", text: "2 / 2")
    saved.reload
    find(".round-choice[value='#{saved.question.fetch('target_id')}']").click
    click_button "Round summary"
    expect(page).to have_content("2 / 2")
    click_link "Play again"
    expect(page).to have_content("Focused players · Jalen Brunson · Josh Hart")
  ensure
    page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride"
  end
end
