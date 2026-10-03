require "rails_helper"

RSpec.describe "Account and history pages", type: :system do
  let(:ace) { create(:ace) }
  let(:team) { create(:team, territory: "New York", mascot: "Yankees") }
  let(:player) { create(:player, team: team, first_name: "Aaron", last_name: "Judge") }

  before { driven_by :selenium_chrome_headless }
  after { page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride" }

  def phone_viewport
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false
  end

  def expect_no_horizontal_overflow
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
  end

  it "keeps the player destination through account help and a failed sign-in" do
    visit player_path(player)
    click_link "Sign In", match: :first
    expect(page).to have_css("h1", text: /sign in/i)
    page.save_screenshot Rails.root.join("tmp/screenshots/account-sign-in-desktop.png")

    phone_viewport
    expect_no_horizontal_overflow
    page.save_screenshot Rails.root.join("tmp/screenshots/account-sign-in-mobile.png")
    click_link "Create an account"
    expect(page).to have_field("Confirm password")
    expect_no_horizontal_overflow
    page.save_screenshot Rails.root.join("tmp/screenshots/account-sign-up-mobile.png")
    within(".account-links") { click_link "Sign in" }
    click_link "Forgot your password?"
    expect(page).to have_button("Send reset instructions")
    expect_no_horizontal_overflow
    page.save_screenshot Rails.root.join("tmp/screenshots/account-reset-mobile.png")
    within(".account-links") { click_link "Sign in" }

    fill_in "Email", with: ace.email
    fill_in "Password", with: "wrong-password"
    within(".account-form") { click_button "Sign in" }
    expect(page).to have_content("Invalid email or password.")
    fill_in "Password", with: "password123"
    within(".account-form") { click_button "Sign in" }
    expect(page).to have_current_path(player_path(player))
    expect(page).to have_css("h1", text: /Aaron Judge/i)
  end

  it "shows daily results, filters team history and keeps a mix-up drill focused across rounds" do
    rival = create(:team, territory: "Boston", mascot: "Red Sox", league: team.league)
    rival_player = create(:player, team: rival, first_name: "Rafael", last_name: "Devers")
    unrelated = create(:team, league: team.league)
    create(:player, team: unrelated)
    division = create(:division, name: "American League East")
    now = Time.current
    [6, 5, 3, 2, 1, 0].each do |days_ago|
      create(:game_attempt, ace: ace, subject_entity: player, created_at: now - days_ago.days)
      next if days_ago == 2

      create(:game_attempt, ace: ace, subject_entity: player, chosen_entity: rival, is_correct: false, created_at: now - days_ago.days)
    end
    create(:game_attempt, ace: ace, subject_entity: rival_player, chosen_entity: team, is_correct: false)
    create(:game_attempt, ace: ace, subject_entity: player, created_at: 8.days.ago)
    create(:game_attempt, ace: ace, game_type: "guess_the_division", subject_entity: team, target_entity: division, chosen_entity: division)
    sign_in ace
    visit strength_game_attempts_path
    expect(page).to have_content("6 mix-ups")
    point = all(".history-chart-point").last
    point.click
    expect(point).to have_css("[role=tooltip]", text: "2 of 4 correct", visible: true)
    page.save_screenshot Rails.root.join("tmp/screenshots/game-history-desktop.png")

    phone_viewport
    expect_no_horizontal_overflow
    page.save_screenshot Rails.root.join("tmp/screenshots/game-history-mobile.png")
    page.scroll_to find("#history-mixups-title"), align: :top
    page.save_screenshot Rails.root.join("tmp/screenshots/game-history-insights-mobile.png")
    select "Guess the Division", from: "Game"
    click_button "Apply"
    expect(page).to have_css(".history-attempt", count: 1)
    expect(page).not_to have_content("Teams you mix up")
    within(".history-tabs") { click_link "By team" }
    click_link "New York Yankees 1 of 1 correct 100%"
    expect(page).to have_current_path(team_strength_game_attempts_path(team, game_type: "guess_the_division"))
    expect(page).to have_css(".history-attempt", count: 1)
    expect(page).to have_link("Practice Team Match", href: new_game_round_path(team_id: team.id))

    visit strength_game_attempts_path
    find("a[aria-label='Drill New York Yankees and Boston Red Sox']").click
    click_button "Start round"
    expect(page).to have_css(".round-choice", count: 2)
    expect(all(".round-choice").map { |choice| choice[:value].to_i }).to match_array([team.id, rival.id])
    first(".round-choice").click
    click_button "Next"
    expect(page).to have_css(".round-choice:not([disabled])", count: 2)
    expect(all(".round-choice").map { |choice| choice[:value].to_i }).to match_array([team.id, rival.id])
  end
end
