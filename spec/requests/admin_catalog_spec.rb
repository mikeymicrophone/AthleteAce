require "rails_helper"

RSpec.describe "Admin sports data", type: :request do
  let(:admin) { create(:ace, :admin) }
  let(:team) { create(:team, territory: "New York", mascot: "Knicks", abbreviation: "NYK", entity_code: "AA:TEAM:NYK") }
  let(:player) { create(:player, first_name: "Jalen", last_name: "Brunson", nicknames: [ "JB" ], active: true, current_position: "PG", team: team) }

  def save_player(**overrides)
    patch admin_catalog_record_path(player, kind: "players"), params: { version: Admin::EditCatalog.version(player.reload),
      request_key: SecureRandom.uuid, record: { first_name: "Jalen Marquis" } }.merge(overrides)
  end

  it "limits editing and correction history to admins" do
    get admin_catalog_records_path
    expect(response).to redirect_to(new_ace_session_path)
    [ create(:ace), create(:ace, moderator: true) ].each do |viewer|
      sign_in viewer
      get edit_admin_catalog_record_path(player, kind: "players")
      expect(response).to have_http_status(:see_other)
      get admin_catalog_edits_path
      expect(response).to have_http_status(:see_other)
      save_player
      expect(player.reload.first_name).to eq("Jalen")
    end
    sign_in admin
    get edit_admin_catalog_record_path(player, kind: "players")
    expect(response).to have_http_status(:ok)
    expect(response.headers["Cache-Control"]).to include("private", "no-store")
  end

  it "searches literally by name, nickname and code and combines league, team, position, status and photo filters" do
    player
    create(:player, first_name: "Josh", last_name: "Hart", team: team, active: nil, photo_urls: [ "https://example.org/hart.jpg" ])
    sign_in admin
    get admin_catalog_records_path(q: "JB", league_id: team.league_id, team_id: team.id, position: "PG", status: "active", photo: "missing")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Jalen Brunson")
    expect(response.body).not_to include("Josh Hart")
    get admin_catalog_records_path(q: "%")
    expect(response.body).not_to include("Jalen Brunson")
    get admin_catalog_records_path(status: "unknown", photo: "present")
    expect(response.body).to include("Josh Hart")
    expect(response.body).not_to include("Jalen Brunson")
    get admin_catalog_records_path(kind: "teams", q: "AA:TEAM:NYK")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("New York Knicks", "NYK")
  end

  it "rejects malformed filters and unsupported record types" do
    sign_in admin
    [ { q: [ "Jalen" ] }, { league_id: "1tail" }, { status: "retired" }, { photo: "bad" }, { edited: "bad" }, { kind: "teams", status: "active" } ].each do |filters|
      get admin_catalog_records_path, params: filters
      expect(response).to have_http_status(:bad_request)
    end
    get edit_admin_catalog_record_path(player, kind: "aces")
    expect(response).to have_http_status(:not_found)
  end

  it "saves immediately, prompts for a reason and preserves the original audit when explaining an older edit" do
    sign_in admin
    save_player
    first = CatalogEdit.sole
    expect(response).to redirect_to(admin_catalog_edit_path(first))
    expect(player.reload.first_name).to eq("Jalen Marquis")
    follow_redirect!
    expect(response.body).to include("Saved. Why did you make this change?", "Jalen", "Jalen Marquis", "Reason not supplied", "Skip for now")
    save_player(record: { last_name: "Brunsón" })
    second = CatalogEdit.order(:id).last
    patch admin_catalog_edit_path(first), params: { reason: "Roster gives his full first name.", record_id: second.id, after_values: { first_name: "Forged" } }
    expect(response).to redirect_to(admin_catalog_edit_path(first))
    expect(first.reload.reason).to eq("Roster gives his full first name.")
    expect(first.after_values).to eq("first_name" => "Jalen Marquis")
    expect(second.reload.reason).to be_nil
    get admin_catalog_edits_path(pending: "1")
    expect(response.body).to include("Edit ##{second.id}")
    expect(response.body).not_to include("Edit ##{first.id}")
  end

  it "keeps failed or unauthorized reasons missing and does not overwrite a supplied reason" do
    sign_in admin
    save_player
    edit = CatalogEdit.sole
    patch admin_catalog_edit_path(edit), params: { reason: " " }
    expect(response).to have_http_status(:unprocessable_content)
    expect(edit.reload.reason).to be_nil
    sign_in create(:ace, :admin)
    patch admin_catalog_edit_path(edit), params: { reason: "Other admin" }
    expect(response).to have_http_status(:forbidden)
    sign_in admin
    patch admin_catalog_edit_path(edit), params: { reason: "Roster correction" }
    patch admin_catalog_edit_path(edit), params: { reason: "Changed explanation" }
    expect(response).to have_http_status(:conflict)
    expect(edit.reload.reason).to eq("Roster correction")
  end

  it "shows validation and stale-save errors without changing the catalog or audit" do
    sign_in admin
    version = Admin::EditCatalog.version(player)
    player.update!(last_name: "Brunsón")
    save_player(version: version)
    expect(response).to have_http_status(:conflict)
    expect(response.body).to include("Reload current record")
    save_player(record: { birthdate: "invalid" })
    expect(response).to have_http_status(:unprocessable_content)
    expect(CatalogEdit.count).to eq(0)
    expect(player.reload.first_name).to eq("Jalen")
  end

  it "paginates 25 records and exposes edit history as history rather than reseed protection" do
    sign_in admin
    26.times { |n| create(:player, first_name: "Jalen", last_name: "Brunson #{n.to_s.rjust(2, '0')}", team: team) }
    get admin_catalog_records_path(q: "Brunson")
    expect(response.body).to include("Brunson 24")
    expect(response.body).not_to include("Brunson 25")
    get admin_catalog_records_path(q: "Brunson", page: 2)
    expect(response.body).to include("Brunson 25")
    save_player
    get admin_catalog_records_path(edited: "yes")
    expect(response.body).to include("Jalen Marquis Brunson", "Has edit history")
    expect(response.body).not_to include("Brunson 25")
  end

  it "matches history by entity code after a rebuild instead of attaching it to a reused numeric ID" do
    player.update!(entity_code: "AA:PLAYER:BRUNSON")
    sign_in admin
    save_player
    edit = CatalogEdit.sole
    old_id = player.id
    player.destroy!
    replacement = create(:player, first_name: "Josh", last_name: "Hart", id: old_id, entity_code: "AA:PLAYER:HART", team: team)
    rebuilt = create(:player, first_name: "Jalen", last_name: "Brunson", entity_code: "AA:PLAYER:BRUNSON", team: team)
    get edit_admin_catalog_record_path(replacement, kind: "players")
    expect(response.body).not_to include("Edit ##{edit.id}")
    get edit_admin_catalog_record_path(rebuilt, kind: "players")
    expect(response.body).to include("Edit ##{edit.id}")
    get admin_catalog_records_path(edited: "yes")
    expect(response.body).to include("Jalen Brunson")
    expect(response.body).not_to include("Josh Hart")
  end
end
