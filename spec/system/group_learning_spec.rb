require "rails_helper"

RSpec.describe "Group progress and remaining practice", type: :system do
  it "finishes the last remaining name, updates coverage and offers later misses on mobile" do
    ace = create(:ace)
    team = create(:team)
    rival = create(:team, league: team.league)
    jalen = create(:player, first_name: "Jalen", last_name: "Brunson", team: team, photo_urls: [ "/icon.png" ])
    josh = create(:player, first_name: "Josh", last_name: "Hart", team: rival, active: false, photo_urls: [ "/icon.png" ])
    group = PlayerGroup.create!(name: "Knicks names", players: [ jalen, josh ])
    create(:game_attempt, ace: ace, subject_entity: jalen, is_correct: true)
    sign_in ace
    visit player_group_path(group)
    expect(page).to have_content("1 of 2")
    expect(page).to have_content("Not practiced")
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false
    expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
    page.save_screenshot Rails.root.join("tmp/screenshots/group-learning-mobile.png")
    click_link "Practice remaining 1"
    expect(page).to have_select("Members to practice", selected: "Not yet answered correctly")
    expect(page).to have_content("1 player available")
    choose "Image Recognition"
    expect(page).to have_css(".round-start-dock", text: "Image Recognition")
    expect(page).to have_select("Members to practice", selected: "Not yet answered correctly")
    click_button "Start round"
    expect(page).to have_css(".round-game-progress", text: "1 / 1")
    round = ace.game_rounds.last
    expect(round.game_type).to eq("image_recognition")
    expect(round.question.fetch("subject_id")).to eq(josh.id)
    expect(page).to have_css(".round-choice", count: 2)
    find(".round-choice[value='#{josh.id}']").click
    expect(page).to have_css(".round-feedback", text: /Correct/i)
    click_button "Round summary"
    click_link "Play again"
    expect(page).to have_button("Start round", disabled: true)
    expect(page).to have_content("Choose All members")
    visit player_group_path(group)
    expect(page).to have_content("Every current member has been answered correctly")
    expect(page).not_to have_link("Practice remaining")
    create(:game_attempt, ace: ace, subject_entity: josh, is_correct: false)
    visit player_group_path(group)
    expect(page).to have_content("2 of 2")
    click_link "Practice misses"
    expect(page).to have_select("Members to practice", selected: "Needs practice")
    expect(page).to have_content("1 player available")
    select "Any players", from: "Player group"
    expect(page).not_to have_select("Members to practice")
    expect(page).not_to have_content("requires a player group")
    page.execute_script("document.documentElement.dataset.theme = 'dark'")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
  ensure
    page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride"
  end
end
