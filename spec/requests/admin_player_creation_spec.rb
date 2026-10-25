require "rails_helper"

RSpec.describe "Admin player creation", type: :request do
  let(:admin) { create(:ace, :admin) }
  let(:sport) { create(:sport, name: "Basketball", entity_code: "BASKETBALL") }
  let(:key) { SecureRandom.uuid }
  let(:input) { { request_key: key, entity_code: "PLAYER-JORDAN-REED-1998", sport_id: sport.id.to_s,
    record: { first_name: " Jordan ", last_name: "Reed", active: "unknown", nicknames: "JR\nJordan R.", birthdate: "1998-02-01", photo_urls: "https://example.org/reed.jpg" } } }

  def create_player(**overrides)
    post admin_catalog_records_path(kind: "players"), params: input.merge(overrides)
  end

  it "limits new and create to admins and does not offer team creation" do
    get new_admin_catalog_record_path
    expect(response).to redirect_to(new_ace_session_path)
    [ create(:ace), create(:ace, moderator: true) ].each do |viewer|
      sign_in viewer
      get new_admin_catalog_record_path
      expect(response).to have_http_status(:see_other)
      expect { create_player }.not_to change(Player, :count)
    end
    sign_in admin
    get new_admin_catalog_record_path
    expect(response).to have_http_status(:ok)
    expect(response.headers["Cache-Control"]).to include("private", "no-store")
    get new_admin_catalog_record_path(kind: "teams")
    expect(response).to have_http_status(:not_found)
    post admin_catalog_records_path(kind: "teams"), params: input
    expect(response).to have_http_status(:not_found)
  end

  it "saves an unassigned player, a stable code binding and a creation snapshot before requesting a reason" do
    sign_in admin
    team = create(:team)
    create_player(record: input[:record].merge(team_id: team.id, entity_code: "FORGED", sport_id: team.league.sport_id))
    expect(response).to have_http_status(:see_other)
    edit = CatalogEdit.sole
    player = Player.find(edit.record_id)
    expect(player.attributes).to include("first_name" => "Jordan", "last_name" => "Reed", "team_id" => nil, "sport_id" => sport.id, "active" => nil, "entity_code" => input[:entity_code])
    expect(player.nicknames).to eq([ "JR", "Jordan R." ])
    expect(EntityCode.find_by!(namespace: "MIC", catalog: "ALA", code: input[:entity_code]).resolved_record).to eq(player)
    expect(edit.before_values).to eq({})
    expect(edit.after_values).to include("entity_code" => player.entity_code, "sport_id" => sport.id, "first_name" => "Jordan")
    expect([ Contract.count, Stint.count, Appearance.count, JerseyNumberAssignment.count ]).to eq([ 0, 0, 0, 0 ])
    follow_redirect!
    expect(response.body).to include("Created a new player", "There was no previous record", "Reason not supplied", "Skip for now")
    patch admin_catalog_edit_path(edit), params: { reason: "Added from the published club roster." }
    expect(edit.reload.reason).to eq("Added from the published club roster.")
    expect(edit.export_entry[:before]).to eq({})
    get admin_catalog_records_path(edited: "yes")
    expect(response.body).to include("Jordan Reed")
  end

  it "reuses identical retries and blocks a creation key reused for other values or an edit" do
    sign_in admin
    create_player
    first = CatalogEdit.sole
    expect { create_player }.not_to change(Player, :count)
    expect(response).to redirect_to(admin_catalog_edit_path(first))
    create_player(entity_code: "PLAYER-ANOTHER")
    expect(response).to have_http_status(:conflict)
    expect(CatalogEdit.count).to eq(1)
    player = Player.find(first.record_id)
    patch admin_catalog_record_path(player, kind: "players"), params: { request_key: key, version: Admin::EditCatalog.version(player), record: { first_name: "Jay" } }
    expect(response).to have_http_status(:conflict)
    expect(player.reload.first_name).to eq("Jordan")
  end

  it "rejects invalid names, code shapes, sport choices and profile values without partial rows" do
    sign_in admin
    [ { entity_code: "" }, { entity_code: "BAD:CODE" }, { entity_code: "MIC-ALA-PLAYER-NEW" }, { entity_code: [ "PLAYER" ] },
      { sport_id: "1tail" }, { sport_id: (sport.id + 100).to_s }, { record: { first_name: " ", last_name: " " } },
      { record: { first_name: "Jordan", photo_urls: "javascript:alert(1)" } }, { record: { first_name: "Jordan", birthdate: "bad" } }, { record: { first_name: "Jordan", birthdate: "0000-01-01" } } ].each do |overrides|
      create_player(**overrides)
      expect(response).to have_http_status(:unprocessable_content)
      expect([ Player.count, CatalogEdit.count, EntityCode.count ]).to eq([ 0, 0, 0 ])
    end
    expect(response.body).to include("Add player")
  end

  it "rolls player/code creation back on audit failure and refuses existing code bindings" do
    sign_in admin
    allow(CatalogEdit).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(CatalogEdit.new))
    create_player
    expect(response).to have_http_status(:unprocessable_content)
    expect([ Player.count, EntityCode.count ]).to eq([ 0, 0 ])
    allow(CatalogEdit).to receive(:create!).and_call_original
    EntityCode.create!(namespace: "MIC", catalog: "ALA", code: input[:entity_code], canonical_code: "EXISTING-IDENTITY")
    create_player
    expect(response).to have_http_status(:unprocessable_content)
    expect([ Player.count, CatalogEdit.count, EntityCode.count ]).to eq([ 0, 0, 1 ])
    expect(EntityCode.sole.canonical_code).to eq("EXISTING-IDENTITY")
  end

  it "rolls back a second creation using an existing player's code" do
    sign_in admin
    create_player
    first = CatalogEdit.sole
    create_player(request_key: SecureRandom.uuid)
    expect(response).to have_http_status(:conflict)
    expect([ Player.count, CatalogEdit.count, EntityCode.count ]).to eq([ 1, 1, 1 ])
    expect(CatalogEdit.sole).to eq(first)
  end

  it "allows an unknown sport and records unknown activity without matching or merging same-name players" do
    existing = create(:player, first_name: "Jordan", last_name: "Reed")
    sign_in admin
    create_player(sport_id: "")
    expect(response).to have_http_status(:see_other)
    created = Player.find(CatalogEdit.sole.record_id)
    expect(created.id).not_to eq(existing.id)
    expect(created.sport).to be_nil
    expect(created.active).to be_nil
  end
end
