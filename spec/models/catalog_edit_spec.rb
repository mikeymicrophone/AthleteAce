require "rails_helper"

RSpec.describe CatalogEdit do
  let(:admin) { create(:ace, :admin, username: "roster_rae", display_name: "Rae Carter") }
  let(:player) { create(:player, first_name: "Jalen", last_name: "Brunson", entity_code: "AA:PLAYER:BRUNSON") }

  def edit_player(attributes = { "first_name" => "Jalen Marquis" }, **options)
    Admin::EditCatalog.call(record: player, actor: admin, attributes: attributes,
      version: Admin::EditCatalog.version(player.reload), request_key: SecureRandom.uuid, **options)
  end

  it "saves the record and immutable original identity and changes in one transaction" do
    edit = edit_player({ "last_name" => "Brunsón", "nicknames" => "JB\nBig Body", "birthdate" => "1996-08-31", "active" => "true" })
    expect(player.reload.last_name).to eq("Brunsón")
    expect(edit.record_name).to eq("Jalen Brunson")
    expect(edit.entity_code).to eq("AA:PLAYER:BRUNSON")
    expect(edit.actor_name).to eq("Rae Carter @roster_rae")
    expect(edit.before_values).to include("last_name" => "Brunson", "nicknames" => [], "birthdate" => nil, "active" => nil)
    expect(edit.after_values).to include("last_name" => "Brunsón", "nicknames" => [ "JB", "Big Body" ], "birthdate" => "1996-08-31", "active" => true)
    expect(edit.reason).to be_nil
    expect { edit.update!(record_name: "Replacement") }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    expect { edit.update!(after_values: { "admin" => true }) }.to raise_error(ActiveRecord::ReadonlyAttributeError)
  end

  it "rolls the catalog change back if recording the audit fails" do
    allow(CatalogEdit).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(CatalogEdit.new))
    expect { edit_player }.to raise_error(ActiveRecord::RecordInvalid)
    expect(player.reload.first_name).to eq("Jalen")
    expect(CatalogEdit.count).to eq(0)
  end

  it "returns the original edit on retry, blocks reused keys and rejects stale snapshots" do
    version, key = Admin::EditCatalog.version(player), SecureRandom.uuid
    original = edit_player(request_key: key, version: version)
    expect(edit_player(request_key: key, version: version)).to eq(original)
    expect { edit_player({ "first_name" => "Jaylen" }, request_key: key) }.to raise_error(Admin::EditCatalog::Conflict)
    expect { edit_player({ "last_name" => "Brunsón" }, version: version) }.to raise_error(Admin::EditCatalog::Conflict)
    expect(CatalogEdit.count).to eq(1)
  end

  it "omits no-op saves, preserves unknown status and supports clearing optional values" do
    expect { expect(edit_player({ "first_name" => "Jalen" })).to be_nil }.not_to change(CatalogEdit, :count)
    player.update!(nicknames: [ "JB" ], active: true, debut_year: 2018)
    edit = edit_player({ "nicknames" => "", "active" => "unknown", "debut_year" => "" })
    expect(edit.after_values).to include("nicknames" => [], "active" => nil, "debut_year" => nil)
  end

  it "validates field names, text shapes, dates, years, URLs, colors and bounded arrays" do
    invalid = [ { "entity_code" => "REPLACEMENT" }, { "first_name" => [ "Jalen" ] }, { "active" => "yes" },
      { "birthdate" => "2026-02-30" }, { "birthdate" => "2026-100" }, { "debut_year" => "2018tail" },
      { "first_name" => "x" * 101 }, { "first_name" => "", "last_name" => "" },
      { "photo_urls" => "javascript:alert(1)" }, { "photo_urls" => "https:///player.jpg" },
      { "nicknames" => (1..31).map { |n| "JB #{n}" }.join("\n") } ]
    invalid.each { |attributes| expect { edit_player(attributes) }.to raise_error(ArgumentError) }
    expect(CatalogEdit.count).to eq(0)
    team = player.team
    version = Admin::EditCatalog.version(team)
    expect { Admin::EditCatalog.call(record: team, actor: admin, attributes: { "primary_color" => "red" }, version: version, request_key: "palette") }.to raise_error(ArgumentError)
    palette = Admin::EditCatalog.call(record: team, actor: admin, attributes: { "primary_color" => "#FFFFFF" }, version: version, request_key: "palette")
    expect(palette.after_values).to include("primary_color" => "#FFFFFF", "text_color" => TeamPalette::DARK_TEXT)
  end

  it "attaches a later reason to the exact edit even after another save to the same player" do
    first = edit_player
    second = edit_player({ "last_name" => "Brunsón" })
    first.supply_reason!(actor: admin, reason: "  Confirmed against the official roster.  ")
    expect(first.reload.reason).to eq("Confirmed against the official roster.")
    expect(first.reason_supplied_at).to be_present
    expect(second.reload.reason).to be_nil
    expect(first.before_values).to eq("first_name" => "Jalen")
    expect(first.after_values).to eq("first_name" => "Jalen Marquis")
    expect { first.supply_reason!(actor: admin, reason: first.reason) }.not_to change { first.reload.reason_supplied_at }
    expect { first.supply_reason!(actor: admin, reason: "A different reason") }.to raise_error(Admin::EditCatalog::Conflict)
    expect { first.update!(reason: "Rewrite") }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "restricts explanations to the original active admin and keeps rejected explanations missing" do
    edit = edit_player
    other_admin = create(:ace, :admin)
    expect { edit.supply_reason!(actor: other_admin, reason: "My explanation") }.to raise_error(Admin::EditCatalog::Forbidden)
    [ "  ", "é" * 2001 ].each { |reason| expect { edit.supply_reason!(actor: admin, reason: reason) }.to raise_error(ArgumentError) }
    admin.update!(admin: false)
    expect { edit.supply_reason!(actor: admin, reason: "Official roster") }.to raise_error(Admin::EditCatalog::Forbidden)
    expect { edit_player }.to raise_error(Admin::EditCatalog::Forbidden)
    expect(edit.reload.reason).to be_nil
  end

  it "allows exactly 2000 Unicode code points and exports stable snapshots after later changes or deletion" do
    edit = edit_player
    edit.supply_reason!(actor: admin, reason: "é" * 2000)
    player.update!(first_name: "J.")
    player.destroy!
    entry = JSON.parse(JSON.generate(edit.reload.export_entry))
    expect(entry).to include("format" => "athlete_ace/catalog_edits/v1", "reason" => "é" * 2000)
    expect(entry["record"]).to include("name" => "Jalen Brunson", "entity_code" => "AA:PLAYER:BRUNSON")
    expect(entry["after"]).to eq("first_name" => "Jalen Marquis")
    expect(CatalogEdit.find(edit.id)).to be_present
  end
end
