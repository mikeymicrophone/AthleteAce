require "rails_helper"

RSpec.describe "Admin competition inspection", type: :request do
  let(:admin) { create(:ace, :admin) }
  let(:league) { create(:nba) }
  let(:season) { create(:season, league: league, year: create(:year, number: 2024)) }
  let(:team) { create(:team, league: league, territory: "Harbor", mascot: "Herons") }
  let(:campaign) { Campaign.create!(team: team, season: season, display_name: "Harbor Herons 2024") }
  let(:competition) { Contest.create!(context: league, name: "Harbor Cup", kind: "cup", begin_date: Date.new(2024, 11, 2), entity_code: "HBL:CUP:2024", format_rules: { rounds: [ { key: "final", name: "Final", best_of: 3 } ], extra: "<script>alert(1)</script>" }) }
  let(:entrant) { Contestant.create!(contest: competition, campaign: campaign, placing: 1, wins: 0, losses: 0) }

  def table_rows
    Nokogiri::HTML(response.body).css("tbody tr")
  end

  it "requires an admin and uses private responses while preserving the Admin shell" do
    get admin_competitions_path
    expect(response).to redirect_to(new_ace_session_path)
    [ create(:ace), create(:ace, moderator: true) ].each do |viewer|
      sign_in viewer
      get admin_competitions_path
      expect(response).to have_http_status(:see_other)
      get admin_competition_path(competition)
      expect(response).to have_http_status(:see_other)
    end
    sign_in admin
    get admin_competitions_path
    expect(response).to have_http_status(:ok)
    expect(response.headers["Cache-Control"]).to include("private", "no-store")
    expect(response.body).to include('data-side="admin"')
    get admin_competition_path(competition)
    expect(response.headers["Cache-Control"]).to include("private", "no-store")
    get admin_catalog_records_path
    expect(response.body).to include(admin_competitions_path)
  end

  it "combines literal search, kind, campaign and award filters and reports distinct recorded counts" do
    entrant
    other_campaign = Campaign.create!(team: create(:team, league: league), season: season)
    Contestant.create!(contest: competition, campaign: other_campaign)
    award = TitleAward.create!(contest: competition, winner: entrant, key: "cup", name: "Harbor Cup winners")
    game = Game.create!(context: league, name: "Cup final")
    Contestant.create!(contest: game, campaign: campaign)
    ContestGame.create!(contest: competition, game: game, metadata: { round: "final" })
    sign_in admin
    filters = { q: "HBL:CUP:2024", kind: "cup", team_id: team.id, season_id: season.id, titles: "awarded" }
    get admin_competitions_path, params: filters
    expect(response).to have_http_status(:ok)
    expect(table_rows.size).to eq(1)
    expect(table_rows.first.css("td").map(&:text).last(3)).to eq(%w[2 1 1])
    [ { q: "%" }, { kind: "playoffs" }, { titles: "none" } ].each do |override|
      get admin_competitions_path, params: filters.merge(override)
      expect(table_rows).to be_empty
    end
    award.destroy!
    get admin_competitions_path, params: filters.merge(titles: "none")
    expect(table_rows.size).to eq(1)
  end

  it "matches team and season on the same campaign in a cross-league cup with no assigned season" do
    entrant
    other_season = create(:season)
    other_campaign = Campaign.create!(team: create(:team, league: other_season.league), season: other_season)
    Contestant.create!(contest: competition, campaign: other_campaign)
    sign_in admin
    get admin_competitions_path, params: { season_id: other_season.id, team_id: team.id }
    expect(table_rows).to be_empty
    get admin_competitions_path, params: { season_id: other_season.id }
    expect(table_rows.size).to eq(1)
    expect(table_rows.text).to include("Harbor Cup", "Not set")
    get admin_competition_path(competition)
    expect(response.body).to include(season.name, other_season.name)
  end

  it "does not infer awards from standings or legacy champion data, preserves rules and zero standings, and links the exact competition's games" do
    entrant
    competition.update!(champion: team)
    sign_in admin
    expect do
      get admin_competition_path(competition)
      expect(response.body).to include("Best of 3", "Harbor Herons 2024")
      expect(table_rows.first.css("td").map(&:text).last(3)).to eq(%w[1 0 0])
      document = Nokogiri::HTML(response.body)
      expect(JSON.parse(document.at_css("pre").text)).to eq(competition.format_rules)
      expect(response.body).not_to include("<script>alert(1)</script>")
      expect(document.css("a").map { |a| a["href"] }).to include(admin_games_path(competition_id: competition.id))
      get admin_competition_path(competition, tab: "titles")
      expect(response.body).to include("No recorded title awards")
    end.not_to change(TitleAward, :count)
    TitleAward.create!(contest: competition, winner: entrant, key: "table", name: "Table winners", awarded_on: Date.new(2024, 12, 1))
    TitleAward.create!(contest: competition, winner: entrant, key: "playoffs", name: "Playoff champions")
    get admin_competition_path(competition, tab: "titles")
    expect(table_rows.size).to eq(2)
    expect(table_rows.text).to include("Table winners", "Playoff champions", "2024-12-01", "Unknown", "Harbor Herons 2024")
  end

  it "shows empty and unknown data without substituting a champion or rules" do
    empty = Contest.create!(context: league)
    sign_in admin
    get admin_competition_path(empty)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Unspecified kind", "No entity code", "Unknown start", "No recorded format rules", "No recorded entrants", "0 linked games")
    expect(table_rows).to be_empty
  end

  it "rejects malformed filters, invalid tabs and games requested as competitions" do
    sign_in admin
    [ { q: [ "bad" ] }, { kind: "x" * 81 }, { team_id: "1tail" }, { season_id: { bad: "value" } }, { titles: "champion" } ].each do |filters|
      get admin_competitions_path, params: filters
      expect(response).to have_http_status(:bad_request)
    end
    get admin_competition_path(competition, tab: "invalid")
    expect(response).to have_http_status(:bad_request)
    game = Game.create!(context: league)
    get admin_competition_path(game)
    expect(response).to have_http_status(:not_found)
  end

  it "paginates competitions with unknown dates last, entrants and title awards in stable order" do
    entrant
    25.times { |n| Contest.create!(context: league, name: "Cup #{n}", begin_date: competition.begin_date) }
    undated = Contest.create!(context: league, name: "Upcoming cup")
    Game.create!(context: league, name: "Excluded game", begin_date: competition.begin_date)
    sign_in admin
    get admin_competitions_path
    expect(table_rows.size).to eq(25)
    expect(table_rows.text).not_to include("Excluded game")
    get admin_competitions_path(page: 2)
    expect(table_rows.css("td:first-child a").map(&:text)).to eq([ competition.name, undated.name ])
    25.times do |n|
      another = Campaign.create!(team: create(:team, league: league), season: season, display_name: "Campaign #{n}")
      Contestant.create!(contest: competition, campaign: another)
      TitleAward.create!(contest: competition, winner: entrant, key: "award_#{n.to_s.rjust(2, '0')}", name: "Award #{n}")
    end
    get admin_competition_path(competition)
    expect(table_rows.size).to eq(25)
    get admin_competition_path(competition, page: 2)
    expect(table_rows.size).to eq(1)
    expect(table_rows.text).to include("Campaign 24")
    TitleAward.create!(contest: competition, winner: entrant, key: "award_25", name: "Award 25")
    get admin_competition_path(competition, tab: "titles")
    expect(table_rows.size).to eq(25)
    get admin_competition_path(competition, tab: "titles", page: 2)
    expect(table_rows.size).to eq(1)
    expect(table_rows.text).to include("Award 25")
  end
end
