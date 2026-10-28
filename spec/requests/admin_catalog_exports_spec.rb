require "rails_helper"
require "csv"

RSpec.describe "Admin catalog CSV exports", type: :request do
  let(:admin) { create(:ace, :admin) }
  let(:team) { create(:team, territory: "New York", mascot: "Knicks", entity_code: "TEAM-NYK") }

  it "exports every filtered player in directory order regardless of the requested page" do
    players = 26.times.map do |index|
      create(:player, first_name: "Export", last_name: format("Player%02d", index), team: team, active: true, current_position: "PG")
    end
    create(:player, first_name: "Export", last_name: "Inactive", team: team, active: false, current_position: "PG")
    sign_in admin
    get admin_catalog_records_path(format: :csv), params: { q: "Export", team_id: team.id, league_id: team.league_id, status: "active", position: "PG", page: 999 }
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/csv")
    expect(response.headers["Cache-Control"]).to include("private", "no-store")
    expect(response.headers["Content-Disposition"]).to include("attachment", "athleteace-players-")
    rows = CSV.parse(response.body, headers: true)
    expect(rows.length).to eq(26)
    expect(rows.map { |row| row["record_id"].to_i }).to eq(players.map(&:id))
    expect(rows.map { |row| row["current_team_code"] }.uniq).to eq([ "TEAM-NYK" ])
    expect(rows.headers).not_to include("email", "editor", "reason", "bio")
    get admin_catalog_records_path(format: :html), params: { q: "Export", team_id: team.id, status: "active", page: 2 }
    link = Nokogiri::HTML(response.body).css('a').find { |node| node.text == 'Export filtered CSV' }
    query = Rack::Utils.parse_query(URI.parse(link["href"]).query)
    expect(query).to include("q" => "Export", "team_id" => team.id.to_s, "status" => "active")
    expect(query).not_to have_key("page")
    expect(link["data-turbo"]).to eq("false")
    get link["href"]
    expect(response.media_type).to eq("text/csv")
    expect(CSV.parse(response.body, headers: true).length).to eq(26)
  end

  it "keeps unknowns, JSON arrays, Unicode and current relationships explicit without inventing historical membership" do
    player = create(:player, first_name: "María,\nLuisa", last_name: "Santos", team: nil, sport: team.league.sport,
      entity_code: "PLAYER-SANTOS", active: nil, nicknames: [ "中文", "One,\nTwo" ], photo_urls: [], current_position: nil)
    sign_in admin
    get admin_catalog_records_path(format: :csv), params: { q: "PLAYER-SANTOS", status: "unknown", photo: "missing" }
    row = CSV.parse(response.body, headers: true).sole
    expect(row["first_name"]).to eq(player.first_name)
    expect(row["entity_code"]).to eq("PLAYER-SANTOS")
    expect(row["active"]).to be_nil
    expect(row["current_team_code"]).to be_nil
    expect(row["current_league_code"]).to be_nil
    expect(row["sport_name"]).to eq(player.sport.name)
    expect(JSON.parse(row["nicknames_json"])).to eq(player.nicknames)
    expect(JSON.parse(row["photo_urls_json"])).to eq([])
    expect(Time.iso8601(row["updated_at_utc"])).to eq(player.updated_at)
  end

  it "exports team identity, division and current player counts, and respects correction-history filters" do
    division = create(:division, entity_code: "DIVISION-ATLANTIC")
    team.update!(league: division.league, founded_year: 1946, url: "https://example.org/knicks")
    Membership.create!(team: team, division: division)
    create_list(:player, 2, team: team)
    Admin::EditCatalog.call(record: team, actor: admin, attributes: { "mascot" => "Knickerbockers" },
      version: Admin::EditCatalog.version(team), request_key: SecureRandom.uuid)
    create(:team, league: division.league)
    sign_in admin
    get admin_catalog_records_path(format: :csv), params: { kind: "teams", edited: "yes", league_id: division.league.id }
    row = CSV.parse(response.body, headers: true).sole
    expect(row["entity_code"]).to eq("TEAM-NYK")
    expect(row["mascot"]).to eq("Knickerbockers")
    expect(row["division_code"]).to eq("DIVISION-ATLANTIC")
    expect(row["league_name"]).to eq(division.league.name)
    expect(row["current_player_count"]).to eq("2")
    expect(row["founded_year"]).to eq("1946")
    expect(row["website_url"]).to eq("https://example.org/knicks")
    expect(row["stadium_code"]).to be_nil
  end

  it "escapes spreadsheet-sensitive cells and emits a valid header-only CSV for an empty result" do
    player = create(:player, first_name: "=1+1", last_name: "\tName", team: team)
    sign_in admin
    get admin_catalog_records_path(format: :csv), params: { q: "=1+1" }
    row = CSV.parse(response.body, headers: true).sole
    expect(row["first_name"]).to eq("'=1+1")
    expect(row["last_name"]).to eq("'\tName")
    expect(player.reload.first_name).to eq("=1+1")
    get admin_catalog_records_path(format: :csv), params: { q: "No matching identity" }
    table = CSV.parse(response.body, headers: true)
    expect(response).to have_http_status(:ok)
    expect(table).to be_empty
    expect(table.headers).to include("entity_code", "current_team_code")
  end

  it "refuses an oversized export rather than truncating, while accepting the exact limit" do
    stub_const("Admin::SportsDirectory::EXPORT_LIMIT", 2)
    create_list(:player, 2, team: team)
    sign_in admin
    get admin_catalog_records_path(format: :csv)
    expect(response).to have_http_status(:ok)
    expect(CSV.parse(response.body, headers: true).length).to eq(2)
    create(:player, team: team)
    get admin_catalog_records_path(format: :csv), params: { limit: 1 }
    expect(response).to have_http_status(:bad_request)
    expect(response.media_type).not_to eq("text/csv")
    expect(response.body).to include("Export exceeds 2 records")
  end

  it "enforces admin access and rejects malformed filters without changing catalog data or its audit" do
    player = create(:player, team: team)
    original = player.attributes
    get admin_catalog_records_path(format: :csv)
    expect(response).to have_http_status(:unauthorized)
    [ create(:ace), create(:ace, moderator: true) ].each do |viewer|
      sign_in viewer
      get admin_catalog_records_path(format: :csv)
      expect(response).to have_http_status(:see_other)
      expect(response.media_type).not_to eq("text/csv")
    end
    sign_in admin
    expect {
      get admin_catalog_records_path(format: :csv)
    }.not_to change(CatalogEdit, :count)
    expect(player.reload.attributes).to eq(original)
    [ { status: "retired" }, { q: [ "Name" ] }, { league_id: "1tail" } ].each do |filters|
      get admin_catalog_records_path(format: :csv), params: filters
      expect(response).to have_http_status(:bad_request)
    end
    get admin_catalog_records_path(format: :csv), params: { kind: "aces" }
    expect(response).to have_http_status(:not_found)
  end
end
