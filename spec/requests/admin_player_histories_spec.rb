require "rails_helper"

RSpec.describe "Admin player history", type: :request do
  let(:admin) { create(:ace, :admin) }
  let(:league) { create(:nba) }
  let(:team) { create(:team, territory: "Harbor", mascot: "Herons", league: league) }
  let(:player) { create(:player, first_name: "Jordan", last_name: "Reed", team: nil, sport: league.sport) }
  let(:season) { create(:season, league: league, year: create(:year, number: 2024)) }
  let(:campaign) { Campaign.create!(team: team, season: season, display_name: "Harbor Herons 2024") }
  let(:organization) { create(:organization, name: "Harbor Basketball Club") }
  let(:contract) { Contract.create!(player: player, organization: organization, start_date: Date.new(2024, 10, 1), entity_code: "HBL:CONTRACT:REED") }
  let(:event) { Transaction.create!(kind: "assignment", effective_on: Date.new(2024, 10, 2), entity_code: "HBL:TRANSACTION:REED", details: { note: "<script>alert(1)</script>" }) }
  let(:stint) { Stint.create!(player: player, team: team, contract: contract, start_transaction: event, start_date: Date.new(2024, 10, 2), end_date: Date.new(2024, 11, 2), status: "assigned") }
  let(:roster) { Roster.create!(campaign: campaign, kind: "game_availability", coverage: "partial", effective_on: Date.new(2024, 11, 2), observed_at: Time.utc(2024, 11, 3, 1, 30)) }
  let(:game) { Game.create!(context: league, name: "Herons vs Foxes", begin_date: Date.new(2024, 11, 2)) }
  let(:contestant) { Contestant.create!(contest: game, campaign: campaign) }

  def rows
    Nokogiri::HTML(response.body).css("tbody tr")
  end

  it "restricts every tab to admins with private no-store responses and Admin side context" do
    get admin_player_history_path(player)
    expect(response).to redirect_to(new_ace_session_path)
    [ create(:ace), create(:ace, moderator: true) ].each do |viewer|
      sign_in viewer
      %w[stints contracts transactions rosters appearances].each do |tab|
        get admin_player_history_path(player, tab: tab)
        expect(response).to have_http_status(:see_other)
      end
    end
    sign_in admin
    get admin_player_history_path(player)
    expect(response).to have_http_status(:ok)
    expect(response.headers["Cache-Control"]).to include("private", "no-store")
    expect(response.body).to include('data-side="admin"')
    get edit_admin_catalog_record_path(player, kind: "players")
    expect(response.body).to include(admin_player_history_path(player))
  end

  it "shows only the player's records and keeps current affiliation separate from historical facts without writing" do
    stint
    TransactionPlayer.create!(event: event, player: player, to_team: team, to_organization: organization)
    RosterEntry.create!(roster: roster, player: player, status: "inactive", jersey_number: "00")
    Appearance.create!(contestant: contestant, player: player, jersey_number: "00", starter: false, statistics: { points: 0 })
    other = create(:player, team: team, sport: league.sport)
    Contract.create!(player: other, organization: organization, entity_code: "OTHER:CONTRACT")
    Stint.create!(player: other, team: team, entity_code: "OTHER:STINT")
    TransactionPlayer.create!(event: event, player: other, entity_code: "OTHER:ENTRY")
    RosterEntry.create!(roster: roster, player: other, entity_code: "OTHER:ROSTER")
    Appearance.create!(contestant: contestant, player: other, entity_code: "OTHER:APPEARANCE")
    sign_in admin
    before_counts = [ Contract.count, Stint.count, Transaction.count, TransactionPlayer.count, RosterEntry.count, Appearance.count, CatalogEdit.count ]
    %w[stints contracts transactions rosters appearances].each do |tab|
      get admin_player_history_path(player, tab: tab)
      expect(response).to have_http_status(:ok)
      expect(rows.size).to eq(1)
      expect(rows.text).not_to include("OTHER:")
      expect(response.body).to include("Current profile team: Unassigned", "#{tab.humanize} (1)")
    end
    expect([ Contract.count, Stint.count, Transaction.count, TransactionPlayer.count, RosterEntry.count, Appearance.count, CatalogEdit.count ]).to eq(before_counts)
    expect(rows.text).to include("Harbor Herons 2024", "No", '"points":0', "00")
    expect(Nokogiri::HTML(response.body).css("a").map { |a| a["href"] }).to include(admin_game_path(game))
  end

  it "preserves unknown contract/stint dates and displays explicitly linked transactions rather than inferring them" do
    stint.update!(start_date: nil, end_date: nil)
    contract.update!(start_date: nil)
    sign_in admin
    get admin_player_history_path(player)
    expect(rows.text).to include("Unknown", "Harbor Basketball Club", "HBL:CONTRACT:REED", "assignment", "2024-10-02", "End: Not linked")
    expect(response.body).to include("Transactions (0)")
    get admin_player_history_path(player, tab: "contracts")
    expect(rows.first.css("td").map(&:text).drop(1).first(3)).to eq([ "Unknown", "Unknown", "Not set" ])
  end

  it "uses day-resolution transaction dates and keeps unknown endpoints and escaped metadata" do
    TransactionPlayer.create!(event: event, player: player, details: { instruction: "<img src=x onerror=alert(1)>" })
    sign_in admin
    get admin_player_history_path(player, tab: "transactions")
    expect(rows.text).to include("2024-10-02", "Not set")
    expect(response.body).to include("day resolution")
    expect(response.body).not_to include("<script>alert(1)</script>", "<img src=x onerror=alert(1)>")
    expect(rows.text).to include('\\u003cscript\\u003e')
  end

  it "separates effective roster dates, observation times, and actual appearances with unknown starter status" do
    RosterEntry.create!(roster: roster, player: player, status: "inactive", details: { reason: "rest" })
    sign_in admin
    get admin_player_history_path(player, tab: "rosters")
    expect(rows.text).to include("2024-11-02", "2024-11-03T01:30:00Z", "partial", "inactive", "rest")
    get admin_player_history_path(player, tab: "appearances")
    expect(response.body).to include("No recorded appearances")
    Appearance.create!(contestant: contestant, player: player, starter: nil)
    get admin_player_history_path(player, tab: "appearances")
    expect(rows.first.css("td")[4].text).to eq("Unknown")
  end

  it "returns empty states, rejects invalid tabs and does not fall back to another player" do
    sign_in admin
    %w[stints contracts transactions rosters appearances].each do |tab|
      get admin_player_history_path(player, tab: tab)
      expect(response.body).to include("No recorded #{tab}")
      expect(rows).to be_empty
    end
    [ "bad", [ "stints" ], { value: "stints" } ].each do |tab|
      get admin_player_history_path(player), params: { tab: tab }
      expect(response).to have_http_status(:bad_request)
    end
    get admin_player_history_path(id: Player.maximum(:id) + 1)
    expect(response).to have_http_status(:not_found)
  end

  it "paginates every tab in stable newest-date/ID order with unknown dates last" do
    26.times do |n|
      day = n.zero? ? nil : Date.new(2024, 10, 2)
      Contract.create!(player: player, organization: organization, start_date: day, entity_code: "CONTRACT:#{n}")
      Stint.create!(player: player, team: team, start_date: day, entity_code: "STINT:#{n}")
      transaction = Transaction.create!(kind: "assignment", effective_on: day)
      TransactionPlayer.create!(event: transaction, player: player, entity_code: "TRANSACTION:#{n}")
      observation = Roster.create!(campaign: campaign, kind: "active", effective_on: day)
      RosterEntry.create!(roster: observation, player: player, entity_code: "ROSTER:#{n}")
      match = Game.create!(context: league, name: "Match #{n}", begin_date: day)
      participant = Contestant.create!(contest: match, campaign: campaign)
      Appearance.create!(contestant: participant, player: player, entity_code: "APPEARANCE:#{n}")
    end
    sign_in admin
    { stints: "STINT:0", contracts: "CONTRACT:0", transactions: "TRANSACTION:0", rosters: "ROSTER:0", appearances: "APPEARANCE:0" }.each do |tab, last_code|
      get admin_player_history_path(player, tab: tab)
      expect(rows.size).to eq(25)
      expect(rows.text).not_to include(last_code)
      get admin_player_history_path(player, tab: tab, page: 2)
      expect(rows.size).to eq(1)
      expect(rows.text).to include(last_code, "Unknown")
    end
  end
end
