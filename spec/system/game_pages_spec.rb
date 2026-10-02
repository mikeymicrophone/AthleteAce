require 'rails_helper'

RSpec.describe "Game pages", type: :system do
  let(:ace) { create(:ace) }
  let(:conference) { create(:conference) }
  let(:league) { conference.league }
  let(:divisions) { create_list(:division, 2, conference: conference) }
  let!(:teams) do
    Array.new(4) do |index|
      create(:team, league: league).tap do |team|
        create(:player, team: team)
        create(:membership, team: team, division: divisions[index % 2])
      end
    end
  end

  before { sign_in ace }

  context "without JavaScript" do
    before { driven_by(:rack_test) }

    it "asks which team a player plays for" do
      visit strength_team_match_path(league_id: league.id)

      expect(page).to have_css(".game-container .subject-card")
      expect(page).to have_content("Who does")
      expect(page).to have_css("[data-game-target='answerChoice']", count: 4)
      expect(page).to have_css("[data-game-target='progressCounter']", text: "0")
    end

    it "asks which division a team is in" do
      visit new_division_game_path

      expect(page).to have_content("Which division")
      expect(page).to have_css("[data-game-target='answerChoice']", minimum: 2)
    end

    it "links from a team to its quiz" do
      visit teams_path
      first(:link, "Quiz Me").click

      expect(page).to have_css(".game-container")
    end

    it "lists teams with attempts on the stats page" do
      attempt = create(:game_attempt, ace: ace, subject_entity: teams.first.players.first)

      visit strength_game_attempts_path

      expect(page).to have_content("Teams by Sport")
      click_link href: team_strength_game_attempts_path(attempt.target_entity)
      expect(page).to have_content(attempt.subject_entity.full_name)
    end
  end

  context "with JavaScript" do
    before { driven_by(:selenium_chrome_headless) }

    it "keeps a mobile quiz readable when player portraits fail to load" do
      teams.each { |team| team.players.update_all(photo_urls: ["/missing-player-portrait.png"]) }
      page.current_window.resize_to 390, 844
      visit strength_team_match_path(league_id: league.id)

      within ".subject-card" do
        expect(page).to have_css(".entity-avatar[data-image-state=fallback]")
        expect(page).to have_css(".entity-initials", visible: true)
        expect(page).not_to have_css(".entity-portrait", visible: true)
      end
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
      page.save_screenshot Rails.root.join("tmp/screenshots/team-match-mobile.png")
      page.current_window.resize_to 1400, 1000
      page.save_screenshot Rails.root.join("tmp/screenshots/team-match-desktop.png")

      teams.each { |team| team.players.update_all(photo_urls: ["/icon.png"]) }
      visit strength_team_match_path(league_id: league.id)
      within ".subject-card" do
        expect(page).to have_css(".entity-avatar[data-image-state=loaded] .entity-portrait", visible: true)
        expect(page).not_to have_css(".entity-initials", visible: true)
      end
    ensure
      page.current_window.resize_to 1400, 1400
    end

    it "pauses with SVG controls and labels wrong and correct answers" do
      visit strength_team_match_path(league_id: league.id)
      click_button "Pause"
      expect(page).to have_css(".pause-button-main[aria-pressed=true] .resume-symbol", visible: true)
      expect(page).not_to have_css("[data-game-target='answerChoice']:not([disabled])")
      click_button "Resume"

      find("[data-game-target='answerChoice'][data-correct=false]", match: :first).click
      expect(page).to have_css(".incorrect-choice .choice-status-incorrect", text: "Incorrect", visible: true)
      expect(page).to have_css(".correct-answer .choice-status-correct", text: "Correct", visible: true)

      expect(page).to have_css("[data-game-target='answerChoice']:not([disabled])")
      find("[data-game-target='answerChoice'][data-correct=true]").click
      expect(page).to have_css("[data-game-target='progressCounter']", text: "1")
      expect(page).to have_css(".correct-choice .choice-status-correct", text: "Correct", visible: true)
    end

    def wait_for_attempts(count)
      Timeout.timeout(Capybara.default_max_wait_time) { sleep 0.1 until GameAttempt.count >= count }
    end

    # Answers the question on screen and returns the player it asked about
    def answer_current_question
      expect(page).to have_css("[data-game-target='answerChoice']:not([disabled])")
      player = Player.find(find("[data-game-target='questionCard']")["data-player-id"])
      first("[data-game-target='answerChoice']").click
      player
    end

    it "records each answer against the question that was on screen" do
      visit strength_team_match_path(league_id: league.id)

      first_player = answer_current_question
      wait_for_attempts(1)
      expect(GameAttempt.last).to have_attributes(subject_entity: first_player, target_entity: first_player.team)

      # The next question loads into the frame after the answer overlay
      second_player = answer_current_question
      wait_for_attempts(2)
      attempt = GameAttempt.order(:id).last
      expect(attempt).to have_attributes(subject_entity: second_player, target_entity: second_player.team)
      expect(attempt.is_correct).to eq(attempt.chosen_entity == second_player.team)
    end
  end
end
