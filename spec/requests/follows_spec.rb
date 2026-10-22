require "rails_helper"

RSpec.describe "Following teams and players", type: :request do
  let(:ace) { create(:ace) }
  let(:team) { create(:team) }
  let(:player) { create(:player, team: team) }

  it "requires sign-in and only accepts teams or players" do
    post follows_path, params: { followable_type: "Team", followable_id: team.id }
    expect(response).to redirect_to(new_ace_session_path)
    sign_in ace
    expect {
      post follows_path, params: { followable_type: "Ace", followable_id: ace.id }
    }.not_to change(Follow, :count)
    expect(response).to have_http_status(:not_found)
    sign_in ace
    post follows_path, params: { followable_type: "Player", followable_id: -1 }
    expect(response).to have_http_status(:not_found)
  end

  it "follows once, updates its button with Turbo, and ignores a posted owner" do
    sign_in ace
    other = create(:ace)
    2.times do
      post follows_path, params: { followable_type: "Player", followable_id: player.id, ace_id: other.id },
        headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Following", "Unfollow #{player.name}", "follow_player_#{player.id}")
    end
    expect(ace.follows.where(followable: player).count).to eq(1)
    expect(other.follows).to be_empty
    follow = ace.follows.sole
    delete follow_path(follow), headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }
    expect(response.body).to include("Follow #{player.name}")
    expect(ace.follows.reload).to be_empty
  end

  it "cannot unfollow for another account" do
    follow = create(:ace).follows.create!(followable: team)
    sign_in ace
    expect { delete follow_path(follow) }.not_to change(Follow, :count)
    expect(response).to have_http_status(:not_found)
  end

  it "shows only the owner's paginated follows on their profile" do
    ace.follows.create!(followable: team)
    ace.follows.create!(followable: player)
    other_team = create(:team)
    create(:ace).follows.create!(followable: other_team)
    sign_in ace
    get profile_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(team.name, player.name, "Following")
    expect(response.body).not_to include(other_team.name)
    5.times { ace.follows.create!(followable: create(:team)) }
    get profile_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('page=2')
  end

  it "redirects HTML submissions back to the followed entity" do
    sign_in ace
    post follows_path, params: { followable_type: "Team", followable_id: team.id }
    expect(response).to redirect_to(team_path(team))
    delete follow_path(ace.follows.sole)
    expect(response).to redirect_to(team_path(team))
  end

  it "removes follows when a player, team or account is deleted" do
    ace.follows.create!(followable: player)
    player.destroy!
    expect(ace.follows.reload).to be_empty
    ace.follows.create!(followable: team)
    team.destroy!
    expect(ace.follows.reload).to be_empty
    ace.follows.create!(followable: create(:team))
    ace.destroy!
    expect(Follow.count).to eq(0)
  end
end
