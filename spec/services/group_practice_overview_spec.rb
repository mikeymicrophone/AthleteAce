require "rails_helper"

RSpec.describe GroupPracticeOverview do
  let(:ace) { create(:ace) }
  let!(:players) { create_list(:player, 3) }

  it "summarizes current membership, lifetime coverage and latest misses for overlapping groups" do
    first = PlayerGroup.create!(name: "First names", players: players.first(2))
    second = PlayerGroup.create!(name: "Next names", players: players.last(2))
    empty = PlayerGroup.create!(name: "Future names")
    create(:game_attempt, ace: ace, subject_entity: players.first, is_correct: true)
    create(:game_attempt, ace: ace, subject_entity: players.first, is_correct: false)
    create(:game_attempt, ace: ace, subject_entity: players.second, is_correct: true)
    create(:game_attempt, ace: ace, subject_entity: players.last, is_correct: true, created_at: 1.day.from_now)
    create(:game_attempt, subject_entity: players.last, is_correct: true)
    progress = PlayProgress.new(ace: ace)

    rows = described_class.new(groups: [ first, second, empty ], progress: progress).rows

    expect(rows).to eq([
      { group: first, total: 2, correct: 2, remaining: 0, missed: 1 },
      { group: second, total: 2, correct: 1, remaining: 1, missed: 0 },
      { group: empty, total: 0, correct: 0, remaining: 0, missed: 0 }
    ])
    first.players.delete(players.first)
    rows = described_class.new(groups: [ first ], progress: PlayProgress.new(ace: ace)).rows
    expect(rows.sole).to include(total: 1, correct: 1, missed: 0)
  end
end
