require "rails_helper"

RSpec.describe "Seasonal Team Match", type: :system do
  it "keeps both teams selected, saves the chosen season and drills historical answers" do
    driven_by :selenium_chrome_headless
    ace = create(:ace)
    league = create(:league, name: "NBA")
    season = create(:season, league: league, label: "2025–26")
    knicks = create(:team, league: league, territory: "New York", mascot: "Knicks")
    nets = create(:team, league: league, territory: "Brooklyn", mascot: "Nets")
    [ knicks, nets ].each do |team|
      campaign = Campaign.create!(team: team, season: season)
      player = create(:player, team: nil, active: false)
      Activation.create!(player: player, campaign: campaign)
    end
    sign_in ace
    visit new_game_round_path(league_id: league.id, team_ids: [ knicks.id, nets.id ])
    expect(page).to have_content("0 players available")
    select season.name, from: "Roster season"
    expect(page).to have_content("2 players available")
    expect(page).to have_checked_field("round_team_#{knicks.id}")
    expect(page).to have_checked_field("round_team_#{nets.id}")
    expect(page).not_to have_field("Include inactive players")
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    page.execute_script("arguments[0].scrollIntoView({block: 'center'});", find(".round-season-select"))
    page.save_screenshot Rails.root.join("tmp/screenshots/round-season-mobile.png")
    click_button "Start round"
    expect(page).to have_css(".round-game-progress", text: "1 / 10")
    expect(page).to have_css(".round-question-prompt", text: /#{Regexp.escape(season.name)}/i)
    round = ace.game_rounds.last
    expect(round.scope.fetch("season_id")).to eq(season.id)
    find(".round-skip").click
    expect(page).to have_css(".round-feedback", text: /Not quite/i)
    question = round.reload.questions.first
    visit strength_path
    within(".play-misses") do
      expect(page).to have_content(season.name)
      click_button "Drill these 1"
    end
    expect(page).to have_css(".round-game-progress", text: "1 / 1")
    expect(ace.game_rounds.last.questions.sole).to eq(question)
    find(".round-choice[value='#{question.fetch('target_id')}']").click
    expect(page).to have_css(".round-feedback", text: /Correct/i)
    expect(Player.where.not(team_id: nil)).to be_empty
    visit new_game_round_path(round.scope)
    expect(page).to have_select("Roster season", selected: season.name)
    choose "Guess the Division"
    expect(page).not_to have_select("Roster season")
    expect(page).not_to have_content("is supported for Team Match only")
  ensure
    page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride"
  end
end
