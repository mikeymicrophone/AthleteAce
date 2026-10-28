require "rails_helper"

RSpec.describe "Admin game inspection", type: :request do
  let(:admin) { create(:ace, :admin) }
  let(:league) { create(:nba) }
  let(:season) { create(:season, league: league) }
  let(:team) { create(:team, league: league, territory: "Harbor", mascot: "Herons") }
  let(:campaign) { Campaign.create!(team: team, season: season, display_name: "Harbor Herons 2024") }
  let(:game) { Game.create!(context: league, name: "Herons vs Foxes", begin_date: Date.new(2024, 11, 2), entity_code: "HBL:GAME:001") }
  let(:entry) { Contestant.create!(contest: game, campaign: campaign) }
  let(:player) { create(:player, first_name: "Jordan", last_name: "Reed", sport: league.sport, team: nil) }

  it "restricts the directory and details to admins with private responses" do
    get admin_games_path
    expect(response).to redirect_to(new_ace_session_path)
    [ create(:ace), create(:ace, moderator: true) ].each do |viewer|
      sign_in viewer
      get admin_games_path
      expect(response).to have_http_status(:see_other)
      get admin_game_path(game)
      expect(response).to have_http_status(:see_other)
    end
    sign_in admin
    get admin_games_path
    expect(response).to have_http_status(:ok)
    expect(response.headers["Cache-Control"]).to include("private", "no-store")
    expect(response.body).to include('data-side="admin"')
    get admin_game_path(game)
    expect(response.headers["Cache-Control"]).to include("private", "no-store")
    get admin_catalog_records_path
    expect(response.body).to include(admin_games_path)
  end

  it "combines historical campaign, competition, inclusive date and literal search filters without duplicating games" do
    entry
    competition = Contest.create!(context: league, name: "Harbor Cup")
    Contestant.create!(contest: competition, campaign: campaign)
    ContestGame.create!(contest: competition, game: game)
    other = create(:team, league: league)
    other_campaign = Campaign.create!(team: other, season: season)
    Contestant.create!(contest: competition, campaign: other_campaign)
    Contestant.create!(contest: game, campaign: other_campaign)
    Appearance.create!(contestant: entry, player: player)
    sign_in admin
    filters = { q: "HBL:GAME:001", competition_id: competition.id, season_id: season.id, team_id: team.id, from: "2024-11-02", to: "2024-11-02", participation: "recorded" }
    get admin_games_path, params: filters
    expect(response).to have_http_status(:ok)
    document = Nokogiri::HTML(response.body)
    expect(document.css("tbody tr").size).to eq(1)
    expect(document.css("tbody").text).to include("Herons vs Foxes", "Harbor Cup", "Harbor Herons 2024")
    expect(document.css("tbody tr td").last.text).to eq("1")
    [ { q: "%" }, { participation: "missing" }, { from: "2024-11-03" }, { to: "2024-11-01" } ].each do |override|
      get admin_games_path, params: filters.merge(override)
      expect(Nokogiri::HTML(response.body).css("tbody tr")).to be_empty
    end
  end

  it "requires the selected team and season to belong to the same participating campaign in cross-league games" do
    entry
    other_season = create(:season)
    other_campaign = Campaign.create!(team: create(:team, league: other_season.league), season: other_season)
    Contestant.create!(contest: game, campaign: other_campaign)
    sign_in admin
    get admin_games_path, params: { season_id: other_season.id, team_id: team.id }
    expect(Nokogiri::HTML(response.body).css("tbody tr")).to be_empty
    get admin_games_path, params: { season_id: other_season.id }
    expect(Nokogiri::HTML(response.body).css("tbody").text).to include(game.name)
  end

  it "rejects malformed filters, invalid calendars and inverted dates" do
    sign_in admin
    [ { q: [ "bad" ] }, { team_id: "1tail" }, { competition_id: "0" }, { season_id: { bad: "value" } }, { from: "2024-2-01" }, { from: "2024-02-30" }, { from: "2024-11-03", to: "2024-11-01" }, { participation: "played" } ].each do |filters|
      get admin_games_path, params: filters
      expect(response).to have_http_status(:bad_request)
    end
    get admin_game_path(game, tab: "invalid")
    expect(response).to have_http_status(:bad_request)
    competition = Contest.create!(context: league)
    get admin_game_path(competition)
    expect(response).to have_http_status(:not_found)
  end

  it "separates explicit roster observations from actual appearances and never infers participation from a current team or date" do
    entry
    roster = Roster.create!(campaign: campaign, kind: "game_availability", coverage: "partial", effective_on: game.begin_date, details: { game_code: game.entity_code })
    RosterEntry.create!(roster: roster, player: player, status: "inactive", jersey_number: "00", details: { reason: "rest" })
    unrelated = Roster.create!(campaign: campaign, kind: "active", effective_on: game.begin_date)
    stranger = create(:player, first_name: "Unrelated", last_name: "Player", sport: league.sport, team: team)
    RosterEntry.create!(roster: unrelated, player: stranger)
    wrong_campaign = Campaign.create!(team: create(:team, league: league), season: season)
    wrong = Roster.create!(campaign: wrong_campaign, kind: "active", details: { game_code: game.entity_code })
    RosterEntry.create!(roster: wrong, player: stranger)
    sign_in admin
    expect do
      get admin_game_path(game)
      expect(response.body).to include("No recorded appearances")
      get admin_game_path(game, tab: "rosters")
    end.not_to change(Appearance, :count)
    expect(response.body).to include("Jordan Reed", "inactive", "rest", "partial", "00")
    expect(response.body).not_to include("Unrelated Player")
    game.update!(entity_code: nil)
    get admin_game_path(game, tab: "rosters")
    expect(response.body).to include("No recorded roster entries")
    expect(response.body).not_to include("Jordan Reed")
  end

  it "paginates explicit roster entries and preserves their status without manufacturing appearances" do
    entry
    roster = Roster.create!(campaign: campaign, kind: "game_availability", coverage: "complete", details: { game_code: game.entity_code })
    26.times do |n|
      athlete = create(:player, first_name: "Morgan", last_name: "Price #{n}", sport: league.sport, team: nil)
      RosterEntry.create!(roster: roster, player: athlete, status: n == 25 ? "inactive" : "active")
    end
    sign_in admin
    get admin_game_path(game, tab: "rosters")
    expect(Nokogiri::HTML(response.body).css("tbody tr").size).to eq(25)
    get admin_game_path(game, tab: "rosters", page: 2)
    expect(Nokogiri::HTML(response.body).css("tbody tr").size).to eq(1)
    expect(response.body).to include("Price 25", "inactive")
    expect(Appearance.count).to eq(0)
  end

  it "paginates games and appearances deterministically, placing unknown dates last and retaining unknown starter status" do
    entry
    sign_in admin
    25.times { |n| Game.create!(context: league, name: "Scheduled #{n}", begin_date: game.begin_date) }
    undated = Game.create!(context: league, name: "Date to be arranged")
    get admin_games_path
    expect(Nokogiri::HTML(response.body).css("tbody tr").size).to eq(25)
    expect(response.body).not_to include(undated.name)
    get admin_games_path(page: 2)
    names = Nokogiri::HTML(response.body).css("tbody tr td:first-child a").map(&:text)
    expect(names).to eq([ game.name, undated.name ])
    26.times do |n|
      athlete = create(:player, first_name: "Jordan", last_name: "Reed #{n}", sport: league.sport, team: nil)
      Appearance.create!(contestant: entry, player: athlete, statistics: { points: n, note: "<script>alert(1)</script>" })
    end
    get admin_game_path(game)
    expect(Nokogiri::HTML(response.body).css("tbody tr").size).to eq(25)
    expect(response.body).to include("Unknown")
    details = Nokogiri::HTML(response.body).css("tbody tr td").last.text
    expect(JSON.parse(details).fetch("note")).to eq("<script>alert(1)</script>")
    expect(response.body).not_to include("<script>alert(1)</script>")
    get admin_game_path(game, page: 2)
    expect(Nokogiri::HTML(response.body).css("tbody tr").size).to eq(1)
    expect(response.body).to include("Reed 25")
  end
end
