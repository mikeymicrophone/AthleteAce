require "rails_helper"

RSpec.describe GameHistory do
  include ActiveSupport::Testing::TimeHelpers
  let(:ace) { create(:ace) }
  let(:team) { create(:team) }
  let(:player) { create(:player, team: team) }

  def attempt(**attributes)
    create :game_attempt, ace: ace, subject_entity: player, **attributes
  end

  it "uses seven calendar days, compares the previous seven, and keeps missing days unknown" do
    Time.use_zone("America/New_York") do
      travel_to Time.zone.local(2026, 10, 2, 12) do
        attempt(created_at: Time.zone.local(2026, 9, 26, 0, 5), is_correct: true)
        attempt(created_at: Time.zone.local(2026, 10, 2, 0, 5), is_correct: false)
        attempt(created_at: Time.zone.local(2026, 9, 25, 23, 55), is_correct: true)
        attempt(created_at: Time.zone.local(2026, 9, 19, 0), is_correct: true)
        attempt(created_at: Time.zone.local(2026, 9, 18, 23, 59), is_correct: false)
        attempt(created_at: 1.day.from_now, is_correct: false)
        create(:game_attempt, subject_entity: player, is_correct: true)

        history = described_class.new ace: ace
        expect(history.current_week).to eq(correct: 1, total: 2, accuracy: 50.0)
        expect(history.previous_week).to eq(correct: 2, total: 2, accuracy: 100.0)
        expect(history.accuracy_change).to eq(-50)
        expect(history.days.last(7).map { |day| day[:accuracy] }).to eq([100.0, nil, nil, nil, nil, nil, 0.0])
      end
    end
  end

  it "does not make an empty history look like zero accuracy or improvement" do
    history = described_class.new ace: ace
    expect(history.current_week[:accuracy]).to be_nil
    expect(history.accuracy_change).to be_nil
    expect(history.team_stats).to be_empty
    expect(history.mixups).to be_empty
  end

  it "combines both directions of a mix-up and excludes other aces, correct guesses and unanswered questions" do
    other_team = create(:team, league: team.league)
    other_player = create(:player, team: other_team)
    2.times { attempt(chosen_entity: other_team, is_correct: false) }
    attempt(subject_entity: other_player, chosen_entity: team, is_correct: false)
    attempt(is_correct: true)
    attempt(chosen_entity: nil, is_correct: false)
    create(:game_attempt, subject_entity: player, chosen_entity: other_team, is_correct: false)

    pair = described_class.new(ace: ace).mixups.sole
    expect(pair[:teams].map(&:id)).to match_array([team.id, other_team.id])
    expect(pair[:count]).to eq(3)
    expect(described_class.new(ace: ace, game_type: "guess_the_division").mixups).to be_empty
  end

  it "attributes Team Match to the recorded team after a transfer and includes division-game teams" do
    wrong_team = create(:team)
    division = create(:division)
    attempt(is_correct: true)
    attempt(chosen_entity: wrong_team, is_correct: false)
    division_attempt = create(:game_attempt, ace: ace, game_type: "guess_the_division", subject_entity: wrong_team,
      target_entity: division, chosen_entity: division, is_correct: true)
    player.update! team: wrong_team

    history = described_class.new ace: ace
    expect(history.team_stats.map { |stat| [stat[:team], stat[:accuracy], stat[:total]] }).to eq([[team, 50.0, 2], [wrong_team, 100.0, 1]])
    expect(described_class.new(ace: ace, team: team).attempts.count).to eq(2)
    expect(described_class.new(ace: ace, team: wrong_team).attempts.to_a).to eq([division_attempt])
    expect(described_class.new(ace: ace, game_type: "guess_the_division").team_stats.map { |stat| stat[:team] }).to eq([wrong_team])
  end
end
