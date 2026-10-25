require "rails_helper"
require "csv"

RSpec.describe "Admin dated jersey numbers", type: :request do
  let(:admin) { create(:ace, :admin) }
  let(:team) { create(:team, territory: "Harbor", mascot: "Herons") }
  let(:player) { create(:player, first_name: "Jordan", last_name: "Reed", team: team) }

  def assignment(number:, **attributes)
    JerseyNumberAssignment.create!(player: player, team: team, number: number, **attributes)
  end

  def row
    Nokogiri::HTML(response.body).css("tbody tr").find { |tr| tr.text.include?(player.name) }
  end

  it "keeps assignment history and directory numbers private to admins" do
    get admin_player_history_path(player, tab: "numbers")
    expect(response).to redirect_to(new_ace_session_path)
    sign_in create(:ace, moderator: true)
    get admin_player_history_path(player, tab: "numbers")
    expect(response).to have_http_status(:see_other)
    sign_in admin
    get admin_player_history_path(player, tab: "numbers")
    expect(response.headers["Cache-Control"]).to include("private", "no-store")
  end

  it "uses inclusive assignment bounds for the current profile team and preserves string numbers in HTML and CSV" do
    assignment(number: "00", start_date: Date.new(2024, 1, 1), end_date: Date.new(2024, 6, 30), entity_code: "HBL:NUMBER:REED:00")
    assignment(number: "7", start_date: Date.new(2024, 7, 1), end_date: Date.new(2024, 12, 31))
    sign_in admin
    { "2024-01-01" => "00", "2024-06-30" => "00", "2024-07-01" => "7", "2024-12-31" => "7", "2025-01-01" => "Unknown" }.each do |day, expected|
      get admin_catalog_records_path, params: { number_on: day, q: player.name }
      expect(response).to have_http_status(:ok)
      expect(row.css("td")[3].text).to eq(expected)
      link = row.css("td")[3].at_css("a")
      expect(link["href"]).to eq(admin_player_history_path(player, tab: "numbers"))
    end
    get admin_catalog_records_path(format: :csv), params: { number_on: "2024-06-30", q: player.name }
    exported = CSV.parse(response.body, headers: true).sole
    expect(exported.to_h).to include("number_on" => "2024-06-30", "assigned_jersey_number" => "00", "number_assignment_code" => "HBL:NUMBER:REED:00")
    get admin_catalog_records_path(format: :csv), params: { number_on: "2025-01-01", q: player.name }
    expect(CSV.parse(response.body, headers: true).sole["assigned_jersey_number"]).to be_nil
  end

  it "uses open bounds as modeled but never substitutes another team's assignment or a roster observation" do
    assignment(number: "001")
    other_team = create(:team, league: team.league)
    JerseyNumberAssignment.create!(player: player, team: other_team, number: "9")
    sign_in admin
    get admin_catalog_records_path, params: { number_on: "1900-01-01", q: player.name }
    expect(row.css("td")[3].text).to eq("001")
    player.update!(team: nil)
    get admin_catalog_records_path, params: { number_on: "2024-01-01", q: player.name }
    expect(row.css("td")[3].text).to eq("Unknown")
    get admin_player_history_path(player, tab: "numbers")
    expect(response.body).to include("Number assignments (2)", "Open start", "Open end", "001")
    expect(Nokogiri::HTML(response.body).css("tbody tr").size).to eq(2)
  end

  it "keeps the number date in pagination and exports, defaults it to the app's current date and rejects malformed dates" do
    player
    sign_in admin
    get admin_catalog_records_path
    document = Nokogiri::HTML(response.body)
    expect(document.at_css('input[name="number_on"]')["value"]).to eq(Date.current.iso8601)
    export = document.css("a").find { |a| a.text == "Export filtered CSV" }
    expect(Rack::Utils.parse_query(URI.parse(export["href"]).query)["number_on"]).to eq(Date.current.iso8601)
    create_list(:player, 25, team: team)
    get admin_catalog_records_path, params: { number_on: "2024-06-30" }
    next_page = Nokogiri::HTML(response.body).css("a[href]").find do |link|
      query = Rack::Utils.parse_query(URI.parse(link["href"]).query)
      query["page"] == "2"
    end
    expect(next_page).to be_present
    expect(Rack::Utils.parse_query(URI.parse(next_page["href"]).query)["number_on"]).to eq("2024-06-30")
    [ "2024-02-30", "2024-2-01", "0000-01-01", [ "2024-01-01" ] ].each do |day|
      get admin_catalog_records_path, params: { number_on: day }
      expect(response).to have_http_status(:bad_request)
      get admin_catalog_records_path(format: :csv), params: { number_on: day }
      expect(response).to have_http_status(:bad_request)
    end
    get admin_catalog_records_path, params: { kind: "teams", number_on: "2024-01-01" }
    expect(response).to have_http_status(:bad_request)
  end

  it "paginates assignment history, preserves source metadata and leaves other players' assignments out" do
    26.times do |n|
      assignment(number: n.to_s, start_date: Date.new(2024, 1, 1) + n, end_date: Date.new(2024, 1, 1) + n,
        entity_code: "NUMBER:#{n}", source: { note: "<script>alert(1)</script>" })
    end
    other = create(:player, team: team)
    JerseyNumberAssignment.create!(player: other, team: team, number: "99", entity_code: "OTHER:NUMBER")
    sign_in admin
    expect do
      get admin_player_history_path(player, tab: "numbers")
      expect(Nokogiri::HTML(response.body).css("tbody tr").size).to eq(25)
      expect(response.body).not_to include("OTHER:NUMBER", "<script>alert(1)</script>")
      get admin_player_history_path(player, tab: "numbers", page: 2)
    end.not_to change(JerseyNumberAssignment, :count)
    expect(Nokogiri::HTML(response.body).css("tbody tr").size).to eq(1)
    expect(response.body).to include("NUMBER:0")
  end

  it "does not turn a roster-only number into an assignment or change directory membership" do
    season = create(:season, league: team.league)
    campaign = Campaign.create!(team: team, season: season)
    roster = Roster.create!(campaign: campaign, kind: "active", effective_on: Date.new(2024, 1, 1))
    RosterEntry.create!(roster: roster, player: player, jersey_number: "8")
    sign_in admin
    get admin_catalog_records_path, params: { number_on: "2024-01-01", q: player.name }
    expect(row.css("td")[3].text).to eq("Unknown")
    expect(JerseyNumberAssignment.count).to eq(0)
    get admin_player_history_path(player, tab: "numbers")
    expect(response.body).to include("No recorded number assignments")
  end
end
