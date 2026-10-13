require "rails_helper"

RSpec.describe "Round team selection", type: :system do
  let(:ace) { create(:ace) }
  let(:league) { create(:league, name: "NBA", sport: create(:sport, name: "Basketball")) }
  let!(:knicks) { create(:team, territory: "New York", mascot: "Knicks", abbreviation: "NYK", league: league) }
  let!(:nets) { create(:team, territory: "Brooklyn", mascot: "Nets", abbreviation: "BKN", league: league) }
  let!(:third) { create(:team, territory: "Boston", mascot: "Celtics", abbreviation: "BOS", league: league) }

  before do
    [ knicks, nets, third ].each { |team| create(:player, team: team, active: true) }
    sign_in ace
    driven_by :selenium_chrome_headless
  end

  after { page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride" }

  it "keeps selected teams across searches and plays only the Knicks and Nets" do
    visit new_game_round_path(league_id: league.id)
    fill_in "Search teams", with: "Knicks"
    click_button "Search"
    expect(page).to have_field("round_team_#{knicks.id}")
    expect(page).not_to have_field("round_team_#{nets.id}")
    check "round_team_#{knicks.id}"
    expect(page).to have_content("1 team selected")
    expect(page).to have_content("1 player available")
    fill_in "Search teams", with: "Nets"
    click_button "Search"
    expect(page).to have_checked_field("round_team_#{knicks.id}")
    check "round_team_#{nets.id}"
    expect(page).to have_content("2 teams selected")
    expect(page).to have_content("2 players available")
    expect(page).to have_checked_field("round_team_#{knicks.id}")
    expect(page).to have_checked_field("round_team_#{nets.id}")
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    page.execute_script("arguments[0].scrollIntoView({block: 'center'});", find(".round-team-selection"))
    page.save_screenshot Rails.root.join("tmp/screenshots/round-multi-team-mobile.png")
    click_button "Start round"
    expect(page).to have_css(".round-game-progress", text: "1 / 10")
    round = ace.game_rounds.last
    expect(round.scope.fetch("team_ids").map(&:to_i)).to match_array([ knicks.id, nets.id ])
    expect(round.questions.map { |question| question.fetch("target_id") }.uniq).to match_array([ knicks.id, nets.id ])
    expect(round.questions.flat_map { |question| question.fetch("choices").map { |choice| choice.fetch("id") } }.uniq).to match_array([ knicks.id, nets.id ])
    visit new_game_round_path(round.scope)
    expect(page).to have_checked_field("round_team_#{knicks.id}")
    expect(page).to have_checked_field("round_team_#{nets.id}")
    uncheck "round_team_#{knicks.id}"
    expect(page).to have_content("1 team selected")
    expect(page).to have_checked_field("round_team_#{nets.id}")
    click_button "Any team"
    expect(page).to have_content("0 teams selected")
    expect(page).to have_content("3 players available")
    expect(page).to have_unchecked_field("round_team_#{nets.id}")
  end

  it "clears teams and the search when switching leagues" do
    other_league = create(:league, name: "Other basketball league", sport: league.sport)
    other = create(:team, league: other_league)
    create(:team, league: other_league)
    create(:player, team: other, active: true)
    visit new_game_round_path(league_id: league.id, team_ids: [ knicks.id, nets.id ], team_query: "Knicks")
    expect(page).to have_content("2 teams selected")
    select other_league.name, from: "League"
    expect(page).to have_content("0 teams selected")
    expect(page).to have_field("Search teams", with: "")
    expect(page).not_to have_field("round_team_#{knicks.id}")
    expect(page).to have_field("round_team_#{other.id}")
  end
end
