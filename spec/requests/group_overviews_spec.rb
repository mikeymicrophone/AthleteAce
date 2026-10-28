require "rails_helper"

RSpec.describe "Group practice overviews", type: :request do
  let(:ace) { create(:ace) }
  let!(:players) { create_list(:player, 2) }

  def practice(group, owner: ace, **attributes)
    GameRoundSetup.new(game_type: "name_ciphers", player_group_id: group.id).start!(owner).tap do |round|
      round.update!(attributes) if attributes.any?
    end
  end

  it "shows three recently practiced surviving groups in activity order, once each and only for the current account" do
    groups = 4.times.map { |i| PlayerGroup.create!(name: "Learning group #{i}", players: players) }
    groups.each_with_index { |group, i| practice(group, updated_at: (10 - i).minutes.ago) }
    practice(groups.last, updated_at: 1.minute.ago)
    hidden = PlayerGroup.create!(name: "Another account's practice", players: players)
    practice(hidden, owner: create(:ace))
    future = PlayerGroup.create!(name: "Future practice", players: players)
    practice(future, updated_at: 1.day.from_now)
    deleted = PlayerGroup.create!(name: "Deleted practice", players: players)
    practice(deleted)
    deleted.destroy!
    sign_in ace

    get strength_path

    doc = Nokogiri::HTML(response.body)
    cards = doc.css(".play-groups .group-practice-card")
    expect(cards.map { |card| card.at_css("h3").text }).to eq(groups.last(3).reverse.map(&:name))
    expect(cards.size).to eq(3)
    expect(cards.text).not_to include(hidden.name, future.name, deleted.name)
    expect(response.body).not_to include(hidden.name)
  end

  it "offers current coverage and remaining/missed practice while keeping visitor pages anonymous" do
    group = PlayerGroup.create!(name: "Courtside names", players: players)
    practice(group)
    create(:game_attempt, ace: ace, subject_entity: players.first, is_correct: true)
    create(:game_attempt, ace: ace, subject_entity: players.first, is_correct: false)
    sign_in ace
    get strength_path
    doc = Nokogiri::HTML(response.body)
    card = doc.at_css(".play-groups .group-practice-card")
    expect(card.text).to include("1 of 2", "Practice remaining 1", "Practice misses")
    href = card.at_css('a[aria-label^="Practice remaining "]')["href"]
    expect(Rack::Utils.parse_nested_query(URI.parse(href).query)).to include("player_group_id" => group.id.to_s, "practice_filter" => "remaining")
    sign_out ace
    get strength_path
    expect(response.body).not_to include("Your groups", group.name)
    get player_groups_path
    expect(response.body).to include(group.name)
    expect(response.body).not_to include("Your group practice", "Practice remaining", "1 of 2", "Practice misses")
  end

  it "shows every public group on the signed-in index with only that account's progress" do
    group = PlayerGroup.create!(name: "Learning roster", players: players)
    empty = PlayerGroup.create!(name: "Unfilled roster")
    players.each { |player| create(:game_attempt, ace: ace, subject_entity: player, is_correct: true) }
    sign_in ace
    get player_groups_path
    expect(response.body).to include("2 of 2", "Every current member answered correctly", empty.name, "No members yet")
    sign_out ace
    sign_in create(:ace)
    get player_groups_path
    expect(response.body).to include(group.name, "0 of 2", "Practice remaining 2")
    expect(response.body).not_to include("2 of 2", "Every current member answered correctly")
  end

  it "keeps the index paginated and leaves groups off Play before any group rounds" do
    (Pagy::OPTIONS[:limit] + 1).times { |i| PlayerGroup.create!(name: "Names #{format('%02d', i)}", players: players) }
    sign_in ace
    get strength_path
    expect(response.body).not_to include("Your groups")
    get player_groups_path
    expect(Nokogiri::HTML(response.body).css(".group-practice-card").size).to eq(Pagy::OPTIONS[:limit])
    get player_groups_path, params: { page: 2 }
    expect(Nokogiri::HTML(response.body).css(".group-practice-card").size).to eq(1)
  end
end
