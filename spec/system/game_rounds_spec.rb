require "rails_helper"

RSpec.describe "Saved rounds", type: :system do
  let(:ace) { create(:ace) }
  let(:sport) { create(:sport, name: "Baseball") }
  let(:league) { create(:league, name: "Major League Baseball", abbreviation: "MLB", sport: sport) }
  let(:conference) { create(:conference, league: league) }
  let!(:east) { create(:division, name: "American League East", abbreviation: "AL East", conference: conference) }
  let!(:west) { create(:division, name: "American League West", abbreviation: "AL West", conference: conference) }
  let!(:team) { create(:team, territory: "New York", mascot: "Yankees", abbreviation: "NYY", league: league) }
  let!(:rival) { create(:team, territory: "Boston", mascot: "Red Sox", abbreviation: "BOS", league: league) }

  before do
    create(:membership, team: team, division: east)
    create(:membership, team: rival, division: west)
    create(:player, team: team, first_name: "Aaron", last_name: "Judge", active: true)
    create(:player, team: rival, first_name: "Rafael", last_name: "Devers", active: true)
    sign_in ace
    driven_by :selenium_chrome_headless
  end

  after { page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride" }

  def phone_viewport
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false
  end

  def no_overflow
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
  end

  it "filters setup, saves progress through pause and refresh, finishes, and drills misses" do
    other_league = create(:league, name: "Basketball League", sport: create(:sport, name: "Basketball"))
    create(:team, league: other_league)
    visit strength_path
    click_link "Pick game & scope"
    select "Baseball", from: "Sport"
    expect(page).to have_select("League", options: ["All leagues", "Major League Baseball"])
    select "Major League Baseball", from: "League"
    expect(page).to have_content("2 players available")
    expect(page).to have_content("Names repeat to fill the round")
    page.save_screenshot Rails.root.join("tmp/screenshots/round-setup-desktop.png")
    phone_viewport
    no_overflow
    page.save_screenshot Rails.root.join("tmp/screenshots/round-setup-mobile.png")
    click_button "Start round"
    expect(page).to have_css(".round-game-progress", text: "1 / 10")
    round = ace.game_rounds.last
    snapshot = round.questions
    no_overflow
    page.save_screenshot Rails.root.join("tmp/screenshots/round-question-mobile.png")

    wrong = snapshot.first.fetch("choices").find { |choice| choice.fetch("id") != snapshot.first.fetch("target_id") }
    find(".round-choice[value='#{wrong.fetch('id')}']").click
    expect(page).to have_css(".round-feedback", text: /Not quite/i)
    expect(page).to have_css(".round-choice-wrong", count: 1)
    page.save_screenshot Rails.root.join("tmp/screenshots/round-feedback-mobile.png")
    page.refresh
    expect(page).to have_css(".round-feedback", text: /Not quite/i)
    expect(round.game_attempts.count).to eq(1)
    # Enter is handled inside the focused feedback, with no document-wide key handler.
    find(".round-feedback").send_keys :enter
    expect(page).to have_css(".round-game-progress", text: "2 / 10")
    click_button "Pause round"
    expect(page).to have_button("Resume round")
    visit strength_path
    expect(page).to have_content("1 of 10 answered")
    within(".round-continue") { click_link "Continue" }
    click_button "Resume round"
    expect(page).to have_css(".round-game-progress", text: "2 / 10")
    expect(round.reload.questions).to eq(snapshot)

    1.upto(9) do |position|
      expect(page).to have_css(".round-game-progress", text: "#{position + 1} / 10")
      target = snapshot[position].fetch("target_id")
      if position == 1
        choice_index = snapshot[position].fetch("choices").index { |choice| choice.fetch("id") == target }
        find(".round-subject h1").send_keys((choice_index + 1).to_s)
      else
        find(".round-choice[value='#{target}']").click
      end
      expect(page).to have_css(".round-feedback", text: /Correct/i)
      click_button(position == 9 ? "Round summary" : "Next")
    end
    expect(page).to have_css("h1", text: /Round complete/i)
    expect(page).to have_content("9 / 10")
    expect(page).to have_css(".round-result", count: 10)
    no_overflow
    page.save_screenshot Rails.root.join("tmp/screenshots/round-summary-mobile.png")
    page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride"
    page.save_screenshot Rails.root.join("tmp/screenshots/round-summary-desktop.png")
    click_button "Drill misses"
    expect(page).to have_css(".round-game-progress", text: "1 / 1")
    expect(page).to have_css(".round-subject", text: /#{Regexp.escape(snapshot.first.fetch('subject_name'))}/i)
    click_button "I don’t know — show me"
    click_button "Round summary"
    expect(page).to have_content("0 / 1")
    expect(ace.game_attempts.count).to eq(11)
  end

  it "plays Guess the Division through the same saved round and result flow" do
    visit new_game_round_path(game_type: "guess_the_division", league_id: league.id)
    expect(page).to have_content("2 teams available")
    click_button "Start round"
    expect(page).to have_content(/Which division is this team in\?/i)
    round = ace.game_rounds.last
    page.save_screenshot Rails.root.join("tmp/screenshots/round-division-desktop.png")
    10.times do |position|
      expect(page).to have_css(".round-game-progress", text: "#{position + 1} / 10")
      find(".round-choice[value='#{round.questions[position].fetch('target_id')}']").click
      click_button(position == 9 ? "Round summary" : "Next")
    end
    expect(page).to have_css("h1", text: /Round complete/i)
    expect(page).to have_content("10 / 10")
    expect(page).not_to have_button("Drill misses")
    click_link "Game history", match: :first
    expect(page).to have_css(".history-attempt", count: 10)
    expect(page).to have_link("View round", count: 10)
  end
end
