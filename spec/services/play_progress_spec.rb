require "rails_helper"

RSpec.describe PlayProgress do
  include ActiveSupport::Testing::TimeHelpers
  let(:ace) { create(:ace) }
  let(:team) { create(:team) }
  let!(:rival) { create(:team, league: team.league) }
  let(:player) { create(:player, team: team) }

  def attempt(**attributes)
    create :game_attempt, ace: ace, subject_entity: player, **attributes
  end

  it "starts empty without inventing knowledge or streaks" do
    progress = described_class.new(ace: ace)
    expect(progress.names_known).to eq(0)
    expect(progress.streaks).to eq(current: 0, best: 0)
    expect(progress.misses).to be_empty
    expect(progress.players_today).to be_empty
  end

  it "requires two correct answers and a correct latest answer to know a name" do
    attempt(is_correct: true)
    expect(described_class.new(ace: ace).names_known).to eq(0)
    attempt(is_correct: true)
    expect(described_class.new(ace: ace).names_known).to eq(1)
    attempt(is_correct: false)
    progress = described_class.new(ace: ace)
    expect(progress.names_known).to eq(0)
    expect(progress.misses.sole[:misses]).to eq(1)
    attempt(is_correct: true)
    progress = described_class.new(ace: ace)
    expect(progress.names_known).to eq(1)
    expect(progress.misses).to be_empty
  end

  it "counts only unresolved misses and orders ties by attempt id" do
    stamp = 1.minute.ago
    2.times { attempt(is_correct: false, created_at: stamp) }
    attempt(is_correct: true, created_at: stamp)
    3.times { attempt(is_correct: false, created_at: stamp) }
    second = create(:player, team: team)
    2.times { attempt(subject_entity: second, is_correct: false) }
    misses = described_class.new(ace: ace).misses
    expect(misses.map { |miss| [ miss[:player], miss[:misses] ] }).to eq([ [ player, 3 ], [ second, 2 ] ])
  end

  it "keeps yesterday's streak alive and counts calendar dates in the selected zone" do
    Time.use_zone("America/New_York") do
      travel_to Time.zone.local(2026, 10, 13, 0, 10) do
        [ 7, 6, 5, 4, 2, 1 ].each { |days| attempt(created_at: days.days.ago, is_correct: true) }
        progress = described_class.new(ace: ace)
        expect(progress.streaks).to eq(current: 2, best: 4)
        attempt(created_at: 15.minutes.ago, is_correct: false) # still yesterday locally
        expect(described_class.new(ace: ace).streaks[:current]).to eq(2)
        expect(described_class.new(ace: ace).players_today).to be_empty
        attempt(is_correct: true)
        expect(described_class.new(ace: ace).streaks).to eq(current: 3, best: 4)
        expect(described_class.new(ace: ace).players_today.to_a).to eq([ player ])
        travel 2.days
        expect(described_class.new(ace: ace).streaks).to eq(current: 0, best: 4)
      end
    end
  end

  it "excludes other aces, future attempts and deleted players" do
    create(:game_attempt, subject_entity: player, is_correct: false)
    2.times { attempt(is_correct: true, created_at: 1.day.from_now) }
    progress = described_class.new(ace: ace)
    expect(progress.names_known).to eq(0)
    expect(progress.misses).to be_empty
    expect(progress.streaks[:current]).to eq(0)
    attempt(is_correct: false)
    Player.where(id: player.id).delete_all
    expect(described_class.new(ace: ace).misses).to be_empty
    expect(described_class.new(ace: ace).names_known).to eq(0)
  end

  it "builds a short saved drill of unique playable missed players only" do
    3.times { attempt(is_correct: false) }
    inactive = create(:player, team: team, active: false)
    attempt(subject_entity: inactive, is_correct: false)
    resolved = create(:player, team: team)
    attempt(subject_entity: resolved, is_correct: false)
    attempt(subject_entity: resolved, is_correct: true)
    orphan_league_player = create(:player)
    attempt(subject_entity: orphan_league_player, is_correct: false)

    round = GameRoundSetup.new(include_inactive: true).start_misses!(ace)
    expect(round.ace).to eq(ace)
    expect(round.length).to eq(2)
    expect(round.questions.map { |q| q.fetch("subject_id") }).to eq([ player.id, inactive.id ])
    expect(round.questions.all? { |q| q.fetch("choices").size >= 2 }).to be(true)
    expect(round.scope["drill"]).to be(true)
    expect(round.scope["include_inactive"]).to be(true)
    round.answer! at: 0, choice_id: team.id
    expect(described_class.new(ace: ace).misses.map { |miss| miss[:player] }).to eq([ inactive ])
  end
end
