require "rails_helper"

RSpec.describe "Name Cipher rounds", type: :system do
  it "retains the season, saves puzzles through pause and refresh, and drills misses" do
    driven_by :selenium_chrome_headless
    ace = create(:ace)
    team = create(:team, territory: "New York", mascot: "Knicks")
    rival = create(:team, league: team.league, territory: "Brooklyn", mascot: "Nets")
    season = create(:season, league: team.league, label: "2025–26")
    [ team, rival ].each_with_index do |club, index|
      campaign = Campaign.create!(team: club, season: season)
      player = create(:player, team: nil, active: false, first_name: [ "Jalen", "Nic" ][index], last_name: [ "Brunson", "Claxton" ][index])
      Activation.create!(player: player, campaign: campaign)
      teammate = create(:player, team: nil, active: false, first_name: [ "Josh", "Cam" ][index], last_name: [ "Hart", "Thomas" ][index])
      Activation.create!(player: teammate, campaign: campaign)
    end
    sign_in ace
    visit new_game_round_path(season_id: season.id, team_ids: [ team.id, rival.id ])
    choose "Name Ciphers"
    expect(page).to have_select("Roster season", selected: season.name)
    expect(page).to have_checked_field("round_team_#{team.id}")
    expect(page).to have_checked_field("round_team_#{rival.id}")
    expect(page).to have_content("4 players available")
    click_button "Start round"
    expect(page).to have_css(".round-game-progress", text: "1 / 4")
    round = ace.game_rounds.last
    saved = round.questions
    expect(page).to have_css(".round-choice", count: 4)
    expect(page).to have_css(".round-cipher-name", text: saved.first.fetch("scrambled_name"))
    expect(page).not_to have_css(".round-subject .entity-avatar")
    page.save_screenshot Rails.root.join("tmp/screenshots/name-cipher-desktop.png")
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    page.save_screenshot Rails.root.join("tmp/screenshots/name-cipher-mobile.png")
    page.refresh
    expect(page).to have_css(".round-cipher-name", text: saved.first.fetch("scrambled_name"))
    click_button "Pause round"
    click_button "Resume round"
    expect(round.reload.questions).to eq(saved)
    click_button "I don’t know — show me"
    expect(page).to have_css(".round-feedback", text: /Not quite/i)
    click_button "Next"
    1.upto(round.length - 1) do |position|
      expect(page).to have_css(".round-game-progress", text: "#{position + 1} / #{round.length}")
      question = saved.fetch(position)
      key = question.fetch("choices").index { |choice| choice.fetch("id") == question.fetch("target_id") } + 1
      find(".round-cipher-name").send_keys key.to_s
      expect(page).to have_css(".round-feedback", text: /Correct/i)
      click_button(position == round.length - 1 ? "Round summary" : "Next")
    end
    expect(page).to have_content("3 / 4")
    expect(page).to have_link(saved.first.fetch("subject_name"), href: player_path(saved.first.fetch("subject_id")))
    click_link "Play again"
    expect(page).to have_checked_field("Name Ciphers")
    expect(page).to have_select("Roster season", selected: season.name)
    visit summary_game_round_path(round)
    click_button "Drill misses"
    expect(page).to have_css(".round-game-progress", text: "1 / 1")
    expect(ace.game_rounds.last.questions.sole).to eq(saved.first)
    visit strength_game_attempts_path(game_type: "name_ciphers")
    expect(page).to have_css(".history-attempt", count: 4)
    visit strength_path
    within(".play-rate-today") { expect(page).to have_content("Jalen Brunson") }
  ensure
    page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride"
  end
end
