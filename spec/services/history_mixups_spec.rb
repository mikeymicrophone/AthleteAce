require "rails_helper"

RSpec.describe "Cross-mode history mix-ups" do
  let(:ace) { create(:ace) }
  let(:league) { create(:league) }
  let!(:team) { create(:team, league: league) }
  let!(:rival) { create(:team, league: league) }
  let!(:jalen) { create(:player, first_name: "Jalen", last_name: "Brunson", team: team, photo_urls: [ "/icon.png" ]) }
  let!(:josh) { create(:player, first_name: "Josh", last_name: "Hart", team: rival, photo_urls: [ "/icon.png" ]) }

  def miss_pair(mode, owner: ace)
    round = GameRoundSetup.new(game_type: mode, player_ids: [ jalen.id, josh.id ]).start!(owner)
    round.questions.each_with_index do |question, index|
      wrong = question.fetch("choices").find { |choice| choice.fetch("id") != question.fetch("target_id") }
      round.answer!(at: index, choice_id: wrong.fetch("id"))
      round.advance!(at: index)
    end
    round
  end

  it "combines team confusions across Team Match, Multiple Choice and due reviews" do
    create(:game_attempt, ace: ace, subject_entity: jalen, chosen_entity: rival, is_correct: false)
    miss_pair("multiple_choice")
    ace.practice_reviews.update_all(due_at: 1.minute.ago)
    miss_pair("phased_repetition")

    pair = GameHistory.new(ace: ace).mixups.sole
    expect(pair[:teams]).to match_array([ team, rival ])
    expect(pair[:count]).to eq(5)
    expect(GameHistory.new(ace: ace, game_type: "multiple_choice").mixups.sole[:count]).to eq(2)
    expect(GameHistory.new(ace: ace, game_type: "phased_repetition").mixups.sole[:count]).to eq(2)
  end

  it "combines player confusions across ciphers, images and reviews without mixing entity types" do
    miss_pair("name_ciphers")
    miss_pair("image_recognition")
    ace.practice_reviews.update_all(due_at: 1.minute.ago)
    miss_pair("phased_repetition")
    miss_pair("multiple_choice")

    history = GameHistory.new(ace: ace)
    expect(history.player_mixups.sole[:players]).to match_array([ jalen, josh ])
    expect(history.player_mixups.sole[:count]).to eq(6)
    expect(history.mixups.sole[:count]).to eq(2)
    expect(GameHistory.new(ace: ace, game_type: "image_recognition").player_mixups.sole[:count]).to eq(2)
    expect(GameHistory.new(ace: ace, game_type: "multiple_choice").player_mixups).to be_empty
  end

  it "excludes other accounts, future attempts, correct answers, skips and missing players" do
    round = miss_pair("name_ciphers")
    round.game_attempts.first.update!(created_at: 1.day.from_now)
    miss_pair("name_ciphers", owner: create(:ace))
    correct = GameRoundSetup.new(game_type: "name_ciphers", player_ids: [ jalen.id, josh.id ]).start!(ace)
    correct.answer!(at: 0, choice_id: correct.question.fetch("target_id"))
    correct.advance!(at: 0)
    correct.answer!(at: 1, choice_id: nil)
    expect(GameHistory.new(ace: ace).player_mixups.sole[:count]).to eq(1)
    josh.destroy!
    expect(GameHistory.new(ace: ace).player_mixups).to be_empty
  end
end
