require "rails_helper"

RSpec.describe GameRound do
  include ActiveSupport::Testing::TimeHelpers
  let(:ace) { create(:ace) }
  let(:team) { create(:team) }
  let!(:rival) { create(:team, league: team.league) }
  let!(:player) { create(:player, team: team) }
  let(:round) { GameRoundSetup.new(team_id: team.id).start! ace }

  it "records one server-scored answer per question, even for retries with another choice" do
    expect { round.answer! at: 0, choice_id: rival.id }.to change(GameAttempt, :count).by(1)
    expect(round.current_attempt).to have_attributes(is_correct: false, target_entity: team, subject_entity: player)
    expect { round.answer! at: 0, choice_id: team.id }.not_to change(GameAttempt, :count)
    round.advance! at: 0
    round.advance! at: 0
    expect(round.reload.position).to eq(1)
    expect { round.answer! at: 0, choice_id: team.id }.to raise_error(GameRound::InvalidAction)
    expect { round.answer! at: 1, choice_id: create(:team).id }.to raise_error(GameRound::InvalidAction)
    expect { round.advance! at: 1 }.to raise_error(GameRound::InvalidAction)
  end

  it "preserves question choices on refresh and pause, excluding paused time" do
    travel_to Time.zone.local(2026, 10, 3, 12) do
      saved_questions = round.questions
      travel 5.seconds
      round.pause!
      expect { round.answer! at: 0, choice_id: team.id }.to raise_error(GameRound::InvalidAction)
      travel 2.hours
      round.resume!
      travel 3.seconds
      round.answer! at: 0, choice_id: team.id
      expect(round.current_attempt.time_elapsed_ms).to eq(8_000)
      expect(round.reload.questions).to eq(saved_questions)
      round.pause!
      travel 1.hour
      round.resume!
      expect(round.current_attempt.time_elapsed_ms).to eq(8_000)
    end
  end

  it "keeps the recorded answer when a player's team changes after the round starts" do
    saved_round = round
    player.update! team: rival
    saved_round.answer! at: 0, choice_id: team.id
    expect(saved_round.current_attempt).to have_attributes(target_entity: team, is_correct: true)
  end

  it "finishes only after advancing the last answer and drills each missed subject once" do
    10.times do |position|
      round.answer! at: position, choice_id: [1, 3].include?(position) ? nil : team.id
      expect(round).not_to be_completed
      round.advance! at: position
    end
    expect(round.reload).to be_completed
    expect(round.stats).to include(correct: 8, answered: 10, best_streak: 6, streak: 6)
    expect(round.game_attempts.where(chosen_entity_id: nil).count).to eq(2)
    drill = round.drill_misses!
    expect(drill.length).to eq(1)
    expect(drill.questions.first.fetch("subject_id")).to eq(player.id)
    expect(drill.questions.first.fetch("choices")).to eq(round.questions[1].fetch("choices"))
  end
end
