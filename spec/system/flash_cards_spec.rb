require "rails_helper"

RSpec.describe "Flash cards", type: :system do
  let(:team) { create(:team, territory: "Cincinnati", mascot: "Reds") }
  let!(:players) { create_list(:player, 2, team: team, current_position: "SP") }

  before do
    driven_by :selenium_chrome_headless
    create(:team, league: team.league)
  end

  it "shows the name, then the team, then the position, then moves to the next card" do
    visit flash_cards_path(team_ids: [ team.id ], delay: 5)
    using_wait_time(6) { expect(page).to have_css(".round-game-progress strong", text: "2 / 2") }
    expect(page).to have_css(".flash-card[data-step='1']:not([hidden])", text: players.second.name).or have_css(".flash-card[data-step='1']:not([hidden])", text: players.first.name)
    expect(page).to have_css(".flash-card[data-step='2']:not([hidden]) .flash-card-team-phrase", text: team.name)
    expect(page).to have_css(".flash-card[data-step='3']:not([hidden]) .flash-card-position", text: "(SP)")
    click_button "Pause"
    expect(page).to have_button("Play")
  end

  it "flips through at your own pace, switches pace mid-deck, and offers a quiz on the deck" do
    visit new_game_round_path(team_ids: [ team.id ])
    choose "Flash Cards"
    expect(page).to have_css(".round-start-dock", text: "Flash Cards · 2 cards")
    click_button "Start flash cards"
    expect(page).to have_css(".flash-card[data-step='3']", text: "(SP)")
    expect(page).to have_button("Previous", disabled: true)
    expect(page).to have_no_button("Pause")
    click_button "Next"
    find("body").send_keys :arrow_left
    expect(page).to have_css(".round-game-progress strong", text: "1 / 2")
    click_button "2s"
    expect(page).to have_button("Pause")
    expect(page).to have_current_path(/delay=2/)
    expect(page).to have_css(".round-game-progress strong", text: "2 / 2")
    click_button "Tap"
    expect(page).to have_no_button("Pause")
    expect(page).to have_link("Shuffle again", href: /delay=0/, visible: :all)
    click_button "Next"
    expect(page).to have_content(/That’s the deck\./i)
    click_link "Quiz me on these"
    expect(page).to have_checked_field("Team Match")
    expect(page).to have_content("Focused players")
  end
end
