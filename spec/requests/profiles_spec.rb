require "rails_helper"

RSpec.describe "Ace profiles", type: :request do
  it "requires authentication for profile access and changes" do
    get profile_path
    expect(response).to redirect_to(new_ace_session_path)
    patch profile_path, params: { ace: { username: "courtside_sam", display_name: "Sam Carter" } }
    expect(response).to redirect_to(new_ace_session_path)
  end

  it "registers a public identity without granting submitted privileges" do
    post ace_registration_path, params: { ace: { username: "Courtside_Tess", display_name: "Tess Moreno",
      email: "tess.moreno@example.test", password: "password123", password_confirmation: "password123", admin: true, moderator: true } }
    expect(response).to redirect_to(new_ace_session_path)
    ace = Ace.find_by! email: "tess.moreno@example.test"
    expect(ace.username).to eq("courtside_tess")
    expect(ace.display_name).to eq("Tess Moreno")
    expect(ace).not_to be_admin
    expect(ace).not_to be_moderator
  end

  it "renders handle conflicts on registration" do
    create(:ace, username: "courtside_tess")
    expect {
      post ace_registration_path, params: { ace: { username: "COURTSIDE_TESS", display_name: "Tess Rivera",
        email: "tess.rivera@example.test", password: "password123", password_confirmation: "password123" } }
    }.not_to change(Ace, :count)
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("has already been taken")
  end

  it "takes an existing account through setup and returns to its saved player" do
    ace = create(:ace, :without_identity)
    player = create(:player)
    get player_path(player)
    post ace_session_path, params: { ace: { email: ace.email, password: "password123" } }
    expect(response).to redirect_to(edit_profile_path)
    follow_redirect!
    expect(response.body).to include("Choose your handle")
    patch profile_path, params: { ace: { username: "courtside_sam", display_name: "Sam Carter" } }
    expect(response).to redirect_to(player_path(player))
    follow_redirect!
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("@courtside_sam")
  end

  it "requires setup in an existing session without losing the destination on a validation error" do
    ace = create(:ace, :without_identity)
    create(:ace, username: "courtside_sam")
    sign_in ace
    get quests_path
    expect(response).to redirect_to(edit_profile_path)
    patch profile_path, params: { ace: { username: "COURTSIDE_SAM", display_name: "Sam Carter" } }
    expect(response).to have_http_status(:unprocessable_content)
    patch profile_path, params: { ace: { username: "bleacher_sam", display_name: "Sam Carter" } }
    expect(response).to redirect_to(quests_path)
  end

  it "does not perform a protected mutation before setup and still permits sign-out" do
    ace = create(:ace, :without_identity)
    sign_in ace
    expect {
      post quests_path, params: { quest: { name: "Learn every starter", description: "Name a starting lineup." } }
    }.not_to change(Quest, :count)
    expect(response).to redirect_to(edit_profile_path)
    delete destroy_ace_session_path
    expect(response).to have_http_status(:see_other)
    get profile_path
    expect(response).to redirect_to(new_ace_session_path)
  end

  it "requires a handle even when setup submits only a name or avatar" do
    ace = create(:ace, :without_identity)
    sign_in ace
    patch profile_path, params: { ace: { display_name: "Sam Carter", avatar_color: Ace::AVATAR_COLORS.fetch("Forest") } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(ace.reload.username).to be_nil
    expect(ace.display_name).to be_nil
  end

  it "keeps appearance controls available during setup without losing the return page" do
    ace = create(:ace, :without_identity)
    sign_in ace
    get quests_path
    patch theme_preference_path, params: { theme: "dark" }, headers: { "Referer" => edit_profile_url }
    expect(response).to redirect_to(edit_profile_path)
    expect(ace.reload.theme).to eq("dark")
    patch profile_path, params: { ace: { username: "courtside_sam", display_name: "Sam Carter" } }
    expect(response).to redirect_to(quests_path)
  end

  it "does not carry an unfinished setup destination into another account's profile edits" do
    incomplete = create(:ace, :without_identity)
    complete = create(:ace)
    sign_in incomplete
    get quests_path
    delete destroy_ace_session_path
    post ace_session_path, params: { ace: { email: complete.email, password: "password123" } }
    expect(response).to redirect_to(strength_path)
    patch profile_path, params: { ace: { display_name: "Tess Rivera" } }
    expect(response).to redirect_to(profile_path)
  end

  it "updates only the current ace's public profile without changing security or another account" do
    ace = create(:ace)
    other = create(:ace)
    sign_in ace
    patch profile_path, params: { id: other.id, ace: { display_name: "Tess Rivera", avatar_color: Ace::AVATAR_COLORS.fetch("Plum"),
      admin: true, moderator: true, email: other.email, password: "replacement123" } }
    expect(response).to redirect_to(profile_path)
    expect(ace.reload.display_name).to eq("Tess Rivera")
    expect(ace.avatar_color).to eq(Ace::AVATAR_COLORS.fetch("Plum"))
    expect(ace).not_to be_admin
    expect(ace).not_to be_moderator
    expect(ace.valid_password?("password123")).to be(true)
    expect(ace.email).not_to eq(other.email)
    expect(other.reload.display_name).to eq("Tess Moreno")
  end

  it "rejects handle renames and invalid avatar colors with a safe form" do
    ace = create(:ace, username: "courtside_tess")
    sign_in ace
    patch profile_path, params: { ace: { username: "renamed_tess", display_name: "Tess Rivera" } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(ace.reload.username).to eq("courtside_tess")
    patch profile_path, params: { ace: { avatar_color: "red; background: url(https://example.net)" } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).not_to include("background: url")
  end

  it "shows author and decision identities without email addresses" do
    author = create(:ace, username: "wrigley_wes", display_name: "Wes Rivera")
    reviewer = create(:ace, moderator: true, username: "bleacher_sam", display_name: "Sam Carter")
    quest = create(:quest, created_by: author)
    sign_in reviewer
    get moderation_path
    expect(response.body).to include("@wrigley_wes", "Wes Rivera")
    expect(response.body).not_to include(author.email, reviewer.email)
    Moderation::Review.call(record: quest, actor: reviewer, action: "approve", status: quest.moderation_status, revision: quest.moderation_revision)
    get moderation_log_path
    expect(response.body).to include("@bleacher_sam", "Sam Carter")
    expect(response.body).not_to include(author.email, reviewer.email)
    sign_out reviewer
    get quest_path(quest)
    expect(response.body).to include("Created by", "@wrigley_wes")
    expect(response.body).not_to include(author.email)
  end
end
