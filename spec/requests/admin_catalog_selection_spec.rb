require "rails_helper"
require "csv"

RSpec.describe "Admin selected catalog exports", type: :request do
  let(:admin) { create(:ace, :admin) }
  let(:team) { create(:team) }
  let(:first) { create(:player, first_name: "Jordan", last_name: "Reed", team: team, active: true) }
  let(:second) { create(:player, first_name: "Morgan", last_name: "Price", team: team, active: true) }

  def export(**filters)
    get admin_catalog_records_path(format: :csv), params: { selection: "selected", selected_ids: [ first.id.to_s, second.id.to_s ] }.merge(filters)
  end

  it "exports only selected matching players once, in directory order, with the chosen number date" do
    create(:player, team: team, active: true)
    JerseyNumberAssignment.create!(player: first, team: team, number: "00")
    sign_in admin
    export(selected_ids: [ first.id.to_s, second.id.to_s, first.id.to_s ], number_on: "2024-06-30", status: "active")
    expect(response).to have_http_status(:ok)
    expect(response.headers["Cache-Control"]).to include("private", "no-store")
    rows = CSV.parse(response.body, headers: true)
    expect(rows.map { |row| row["record_id"].to_i }).to eq([ second.id, first.id ])
    expect(rows.map { |row| row["number_on"] }.uniq).to eq([ "2024-06-30" ])
    expect(rows[1]["assigned_jersey_number"]).to eq("00")
    second.update!(active: false)
    export(status: "active")
    expect(CSV.parse(response.body, headers: true).map { |row| row["record_id"].to_i }).to eq([ first.id ])
    export(q: "No matching identity")
    expect(CSV.parse(response.body, headers: true)).to be_empty
  end

  it "intersects selected IDs with correction-history filters rather than exporting other corrected records" do
    outside = create(:player, team: team)
    [ first, outside ].each do |player|
      Admin::EditCatalog.call(record: player, actor: admin, attributes: { "current_position" => "Guard" },
        version: Admin::EditCatalog.version(player), request_key: SecureRandom.uuid)
    end
    sign_in admin
    export(edited: "yes")
    expect(CSV.parse(response.body, headers: true).map { |row| row["record_id"].to_i }).to eq([ first.id ])
  end

  it "handles selected teams separately and keeps spreadsheet protection without mutating data" do
    alpha = create(:team, territory: "=1+1", mascot: "Herons")
    beta = create(:team, territory: "Coastal", mascot: "Foxes")
    create(:team)
    sign_in admin
    before_values = alpha.attributes
    expect do
      export(kind: "teams", selected_ids: [ beta.id.to_s, alpha.id.to_s ])
    end.not_to change(CatalogEdit, :count)
    expect(response).to have_http_status(:ok)
    rows = CSV.parse(response.body, headers: true)
    expect(rows.map { |row| row["record_id"].to_i }).to eq([ alpha.id, beta.id ])
    expect(rows.first["territory"]).to eq("'=1+1")
    expect(rows.headers).not_to include("number_on")
    expect(alpha.reload.attributes).to eq(before_values)
  end

  it "rejects missing, empty, oversized and malformed selections without exporting all records" do
    first
    sign_in admin
    [ nil, "1", [], [ "0" ], [ "1tail" ], [ { id: "1" } ], Array.new(26, "1") ].each do |ids|
      export(selected_ids: ids)
      expect(response).to have_http_status(:bad_request)
      expect(response.media_type).not_to eq("text/csv")
    end
    export(selection: "all")
    expect(response).to have_http_status(:bad_request)
    export(selection: nil)
    expect(response).to have_http_status(:bad_request)
  end

  it "allows 25 selected IDs and ignores the requested page rather than truncating the selection" do
    players = create_list(:player, 25, team: team)
    sign_in admin
    export(selected_ids: players.map { |player| player.id.to_s }, page: 999)
    expect(response).to have_http_status(:ok)
    expect(CSV.parse(response.body, headers: true).length).to eq(25)
  end

  it "retains admin authorization for selected downloads" do
    export
    expect(response).to have_http_status(:unauthorized)
    [ create(:ace), create(:ace, moderator: true) ].each do |viewer|
      sign_in viewer
      export
      expect(response).to have_http_status(:see_other)
    end
  end
end
