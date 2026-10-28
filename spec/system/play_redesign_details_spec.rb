require "rails_helper"

RSpec.describe "Play detail pages", type: :system do
  after { page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride" }

  def phone_viewport
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false
  end

  def expect_no_overflow
    expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
  end

  it "opens the player's public shout-out list from the Play profile on mobile" do
    author = create :ace, display_name: "Avery Morgan"
    reviewer = create :ace, moderator: true
    player = create :player, first_name: "Jordan", last_name: "Reyes"
    buy_credit author
    messages = [ "Always finds the open teammate.", "A calm finish under pressure.", "The extra pass made that play.", "Great energy throughout the game." ]
    messages.each do |message|
      post = submit_credit(ace: author, target: player, message: message, bid: 1)
      review_post(post, action: "approve", reviewer: reviewer)
    end
    phone_viewport
    visit player_path(player, side: "play")
    expect(page).to have_css(".player-shout-outs .shout-out-card", count: 3)
    expect(page).to have_css('body[data-side="play"]')
    expect_no_overflow
    page.execute_script("document.querySelector('.player-shout-outs').scrollIntoView()")
    page.save_screenshot Rails.root.join("tmp/screenshots/player-shout-outs-mobile.png")
    click_link "All player shout-outs"
    expect(page).to have_current_path(player_shout_outs_path(player))
    expect(page).to have_css('body[data-side="feed"]')
    expect(page).to have_css(".shout-out-card", count: 4)
    messages.each { |message| expect(page).to have_content(message) }
    page.execute_script("document.documentElement.dataset.theme = 'dark'")
    expect_no_overflow
    page.save_screenshot Rails.root.join("tmp/screenshots/player-shout-outs-dark.png")
  end

  it "shows approval attribution and recorded versus current quest progress" do
    ace = create :ace
    team = create :team
    players = [ [ "Jordan", "Reyes" ], [ "María", "Calderón" ] ].map do |first_name, last_name|
      create :player, team: team, first_name: first_name, last_name: last_name
    end
    group = PlayerGroup.create! name: "Harbor backcourt", players: players
    quest = create :quest, name: "Know the Harbor backcourt"
    achievement = create :achievement, target: team, name: "Learn the team's players"
    create :highlight, quest: quest, achievement: achievement
    goal = create :goal, ace: ace, quest: quest
    round = GameRoundSetup.new(game_type: "name_ciphers", player_group_id: group.id).start!(ace)
    round.questions.each_with_index do |question, position|
      round.answer!(at: position, choice_id: question.fetch("target_id"))
      round.advance!(at: position)
    end
    sign_in ace
    phone_viewport
    visit quest_path(quest)
    expect(page).to have_css(".quest-approval time")
    visit summary_game_round_path(round)
    expect(page).to have_css(".round-learning-progress", text: quest.name)
    expect(page).to have_css('[data-quest-progress-point="before"]', text: "0% · 0 of 1")
    expect(page).to have_css('[data-quest-progress-point="after"]', text: "100% · 1 of 1")
    expect(page).to have_content("2 of 2 players answered correctly since adoption")
    expect_no_overflow
    page.execute_script("document.querySelector('.round-learning-progress').scrollIntoView()")
    page.save_screenshot Rails.root.join("tmp/screenshots/round-quest-snapshots-mobile.png")
    page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride"
    page.execute_script("document.documentElement.dataset.theme = 'dark'")
    expect_no_overflow
    page.save_screenshot Rails.root.join("tmp/screenshots/round-quest-snapshots-desktop-dark.png")
    expect(goal.reload.status).to eq("completed")
  end
end
