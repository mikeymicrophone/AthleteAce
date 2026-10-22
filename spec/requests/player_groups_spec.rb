require "rails_helper"

RSpec.describe "Player groups", type: :request do
  let!(:player) { create(:player, first_name: "Jalen", last_name: "Brunson") }
  let!(:group) { PlayerGroup.create!(name: "Knicks names", players: [ player ]) }

  it "lets visitors browse groups and carry the group through setup" do
    get player_groups_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(group.name)
    get player_group_path(group)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(player.name, new_game_round_path(player_group_id: group.id, game_type: "name_ciphers").gsub("&", "&amp;"))
    get new_game_round_path(player_group_id: group.id, game_type: "name_ciphers")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('name="player_group_id"', group.name)
  end

  it "restricts edits to admins" do
    post player_groups_path, params: { player_group: { name: "Guest group" } }
    expect(response).to redirect_to(new_ace_session_path)
    sign_in create(:ace)
    expect { patch player_group_path(group), params: { player_group: { name: "Replaced" } } }.not_to change { group.reload.name }
    expect(response).to have_http_status(:see_other)
  end

  it "lets admins create and replace a manually selected membership" do
    sign_in create(:ace, :admin)
    get new_player_group_path
    expect(response).to have_http_status(:ok)
    post player_groups_path, params: { player_group: { name: "Names to learn", player_ids: [ player.id ] } }
    created = PlayerGroup.find_by!(name: "Names to learn")
    expect(response).to redirect_to(player_group_path(created))
    expect(created.players).to eq([ player ])
    patch player_group_path(created), params: { player_group: { name: "My names", player_ids: [ "" ] } }
    expect(created.reload.players).to be_empty
    delete player_group_path(created)
    expect(response).to redirect_to(player_groups_path)
    expect(Player.exists?(player.id)).to be(true)
  end

  it "accepts group achievement targets and preselects them from the group page" do
    sign_in create(:ace)
    get new_achievement_path(target_type: "PlayerGroup", target_id: group.id)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-dynamic-select-selected-id-value="' + group.id.to_s + '"')
    get target_options_achievements_path, params: { type: "PlayerGroup" }
    expect(response.parsed_body).to include({ "id" => group.id, "name" => group.name })
  end
  it "retains the adopted group snapshot while switching game modes" do
    ace = create(:ace)
    quest = create(:quest)
    achievement = create(:achievement, target: group)
    create(:highlight, quest: quest, achievement: achievement)
    entry = create(:goal, ace: ace, quest: quest).goal_achievements.sole
    sign_in ace
    get new_game_round_path(player_group_id: group.id, goal_achievement_id: entry.id, game_type: "name_ciphers")
    expect(response).to have_http_status(:ok)
    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css('form.round-setup-form input[name="goal_achievement_id"]')["value"]).to eq(entry.id.to_s)
    expect(response.body).to include("Practicing the members saved when you adopted this quest.")
  end
end
