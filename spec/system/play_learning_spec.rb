require "rails_helper"

RSpec.describe "Play learning", type: :system do
  let(:ace) { create(:ace) }
  let!(:team) { create(:team, territory: "New York", mascot: "Knicks", abbreviation: "NYK") }
  let!(:rival) { create(:team, league: team.league, territory: "Brooklyn", mascot: "Nets", abbreviation: "BKN") }
  let!(:player) { create(:player, team: team, first_name: "Jalen", last_name: "Brunson") }
  let!(:other_player) { create(:player, team: rival, first_name: "Nic", last_name: "Claxton") }

  after { page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride" }

  def phone
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false
  end

  def no_overflow
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
  end

  it "plays Multiple Choice with saved feedback, pause, results and automatic roster completion" do
    quest = create(:quest, name: "New York names")
    quest.add_achievement(create(:achievement, name: "Learn the Knicks roster", target: team))
    ace.adopt_quest(quest)
    sign_in ace
    visit new_game_round_path(game_type: "multiple_choice", league_id: team.league_id)
    expect(page).to have_select("Question topic", selected: "Current team")
    expect(page).to have_content("2 players available")
    phone
    no_overflow
    page.save_screenshot Rails.root.join("tmp/screenshots/play-multiple-choice-setup.png")
    click_button "Start round"
    expect(page).to have_css(".round-game-progress", text: "1 / 2")
    round = ace.game_rounds.last
    round.length.times do |position|
      expect(page).to have_css(".round-game-progress", text: "#{position + 1} / 2")
      find(".round-choice[value='#{round.questions[position]['target_id']}']").click
      expect(page).to have_css(".round-feedback", text: /Correct/i)
      if position.zero?
        click_button "Pause round"
        expect(page).to have_button("Resume round")
        page.refresh
        click_button "Resume round"
        expect(page).to have_css(".round-feedback", text: /Correct/i)
      end
      click_button(position == round.length - 1 ? "Round summary" : "Next")
    end
    expect(page).to have_content("2 / 2")
    expect(page).to have_content("Names newly known")
    no_overflow
    visit quest_path(quest)
    expect(page).to have_content("Done")
    expect(ace.goals.sole.reload.status).to eq("completed")
    page.execute_script("document.documentElement.dataset.theme = 'dark'")
    no_overflow
    page.save_screenshot Rails.root.join("tmp/screenshots/play-roster-quest-dark.png")
    visit strength_path
    expect(page).to have_content(/Names known/i)
    no_overflow
    page.save_screenshot Rails.root.join("tmp/screenshots/play-learning-home-mobile.png")
  end

  it "plays a due review with the original question and records it under Phased Repetition" do
    round = GameRoundSetup.new(team_id: team.id).start!(ace)
    round.answer!(at: 0, choice_id: nil)
    ace.practice_reviews.update_all(due_at: 1.minute.ago)
    sign_in ace
    visit strength_path
    click_button "Review now"
    expect(page).to have_css(".round-game-bar", text: /Phased Repetition/i)
    expect(page).to have_content(/Jalen Brunson/i)
    find(".round-choice[value='#{team.id}']").click
    expect(page).to have_css(".round-feedback", text: /Correct/i)
    click_button "Round summary"
    expect(page).to have_content("1 / 1")
    visit strength_game_attempts_path(game_type: "phased_repetition")
    expect(page).to have_css(".history-attempt", count: 1)
  end

  it "shows a failed photo without leaking initials or accepting guesses" do
    [ player, other_player ].each { |record| record.update!(photo_urls: [ "/unavailable-player-photo.png" ]) }
    round = GameRoundSetup.new(game_type: "image_recognition").start!(ace)
    sign_in ace
    visit game_round_path(round)
    expect(page).to have_content("This photo could not load")
    expect(page).to have_css(".round-subject h1", text: /Who is this player\?/i)
    expect(page).to have_css('.round-choice:disabled', count: 2)
    expect(page).not_to have_css(".round-subject .round-jersey")
    expect(round.game_attempts.count).to eq(0)
  end

  it "lets a visitor try one question on mobile before sign-up" do
    visit feed_path
    click_link "Try", exact: true
    expect(page).to have_content(/Try one · Team Match/i)
    phone
    no_overflow
    page.save_screenshot Rails.root.join("tmp/screenshots/play-preview-mobile.png")
    within(".round-choices") { first("button").click }
    expect(page).to have_content("Sign in to start saved rounds and track your streak")
    expect(GameAttempt.count).to eq(0)
    expect(GameRound.count).to eq(0)
    expect(page).to have_link("New here? Create a free account")
  end
end
