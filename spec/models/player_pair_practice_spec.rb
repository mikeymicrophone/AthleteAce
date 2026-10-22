require "rails_helper"

RSpec.describe "Focused player-pair practice" do
  let(:ace) { create(:ace) }
  let!(:players) { [ create(:player, team: nil, active: false, photo_urls: [ "/icon.png" ]), create(:player, team: nil, photo_urls: [ "/icon.png" ]) ] }
  let!(:outsider) { create(:player, photo_urls: [ "/icon.png" ]) }

  %w[name_ciphers image_recognition].each do |mode|
    it "keeps #{mode} subjects and choices within the selected retired/unassigned pair" do
      round = GameRoundSetup.new(game_type: mode, player_ids: players.map(&:id), include_inactive: true).start!(ace)
      expect(round.questions.map { |question| question.fetch("subject_id") }).to match_array(players.map(&:id))
      round.questions.each { |question| expect(question.fetch("choices").map { |choice| choice.fetch("id") }).to match_array(players.map(&:id)) }
      expect(round.scope.fetch("player_ids")).to eq(players.map(&:id))
      expect(round.scope_label).to include("2 selected players")
    end
  end

  it "keeps retired players in due pair reviews without requiring an inactive checkbox" do
    round = GameRoundSetup.new(game_type: "name_ciphers", player_ids: players.map(&:id), include_inactive: true).start!(ace)
    round.questions.each_index do |position|
      round.answer!(at: position, choice_id: nil)
      round.advance!(at: position)
    end
    ace.practice_reviews.update_all(due_at: 1.minute.ago)

    review = GameRoundSetup.new(game_type: "phased_repetition", player_ids: players.map(&:id)).start!(ace)

    expect(review.questions.map { |question| question.fetch("subject_id") }).to match_array(players.map(&:id))
  end

  it "rejects missing, duplicate and excessive player selections instead of broadening them" do
    [ [ -1 ], [ players.first.id, players.first.id ], [ players.first.id ] * 31 ].each do |ids|
      setup = GameRoundSetup.new(game_type: "name_ciphers", player_ids: ids)
      expect(setup.available_count).to eq(0)
      expect { setup.start!(ace) }.to raise_error(ActiveModel::ValidationError)
    end
  end

  it "intersects group and player selections without adding unrelated names" do
    group = PlayerGroup.create!(name: "Names to learn", players: players)
    selected = GameRoundSetup.new(game_type: "name_ciphers", player_group_id: group.id, player_ids: [ players.first.id, outsider.id ])
    expect(selected.cipher_pool.players).to eq([ players.first ])
    expect(selected.available_count).to eq(0)
  end
end
