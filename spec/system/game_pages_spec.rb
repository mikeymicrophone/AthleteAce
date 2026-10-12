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
