require "rails_helper"

RSpec.describe "Flash cards", type: :system do
  let(:team) { create(:team, territory: "Cincinnati", mascot: "Reds") }
  let!(:players) { create_list(:player, 2, team: team, current_position: "SP") }

  before do
    driven_by :selenium_chrome_headless
    create(:team, league: team.league)
  end

  it "fades in the position after the team, then moves to the next card" do
    visit flash_cards_path(team_ids: [ team.id ], delay: 5)
    expect(page).to have_css(".flash-card.flash-card-revealed .flash-card-position", text: "(SP)")
    using_wait_time(6) { expect(page).to have_css(".round-game-progress strong", text: "2 / 2") }
    expect(page).to have_css(".flash-card:not(.flash-card-revealed)", text: /is on the\s+\S+\s+#{team.name}/)
    expect(page).to have_css(".flash-card.flash-card-revealed .flash-card-position", text: "(SP)")
    click_button "Pause"
    expect(page).to have_button("Play")
    expect(page).to have_css(".flash-card.flash-card-revealed .flash-card-position", text: "(SP)")
  end

  it "flips through at your own pace and offers a quiz on the deck" do
    visit new_game_round_path(team_ids: [ team.id ])
    choose "Flash Cards"
    expect(page).to have_css(".round-start-dock", text: "Flash Cards · 2 cards")
    click_button "Start flash cards"
    expect(page).to have_css(".flash-card.flash-card-revealed", text: "(SP)")
    expect(page).to have_button("Previous", disabled: true)
    expect(page).to have_no_button("Pause")
    find("body").send_keys :arrow_right
    expect(page).to have_css(".round-game-progress strong", text: "2 / 2")
    click_button "Next"
    expect(page).to have_content(/That’s the deck\./i)
    click_link "Quiz me on these"
    expect(page).to have_checked_field("Team Match")
    expect(page).to have_content("Focused players")
  end
end
