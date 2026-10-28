require "rails_helper"

RSpec.describe "Browse entity pages", type: :request do
  let(:sport) { create :sport, name: "Basketball" }
  let(:country) { create :country, name: "United States" }
  let(:state) { create :state, country: country, name: "California" }
  let(:city) { create :city, state: state, name: "Oakland" }
  let(:stadium) { create :stadium, city: city, name: "Harbor Arena", capacity: 18000, address: "700 Harbor Way" }
  let(:league) { create :league, sport: sport, jurisdiction: country, name: "Pacific Basketball League" }
  let(:conference) { create :conference, league: league }
  let(:division) { create :division, conference: conference }
  let(:team) { create :team, league: league, stadium: stadium, territory: "Oakland", mascot: "Herons" }
  let(:season) { create :season, league: league, champion: team }
  let(:campaign) { Campaign.create! team: team, season: season }

  def document
    Nokogiri::HTML(response.body)
  end

  it "renders each remaining sports, place and time detail with one title and working related links" do
    membership = create :membership, team: team, division: division
    player = create :player, team: team, birth_city: city
    campaign
    [ sport, league, conference, division, country, state, city, stadium, season.year, season, campaign, membership ].each do |record|
      get polymorphic_path(record), params: { side: "play" }
      expect(response).to have_http_status(:ok), "failed #{record.class} detail"
      expect(document.css("main h1").size).to eq(1), "expected one title on #{record.class} detail"
      expect(document.at_css("body")["data-side"]).to eq("play")
      expect(document.css("main a").map { |link| link["href"] }).not_to include(nil, "#")
    end
    get city_path(city)
    expect(document.text).to include("18,000 capacity", "700 Harbor Way", "Players born here", player.name)
    expect(document.css("a").map { |link| link["href"] }).to include(city_teams_path(city), city_stadiums_path(city))
    get year_path(season.year)
    expect(document.css("a").map { |link| link["href"] }).to include(season_path(season))
    expect(document.text).not_to include("This section will be expanded")
  end

  it "shows a bounded player preview with the full count and the scoped complete directory" do
    create_list :player, 13, team: team
    outsider = create :player
    get league_path(league)
    section = document.at_css(".related-section.players")
    expect(section.text).to include("13 players")
    expect(section.css(".related-record").size).to eq(12)
    expect(section.at_css(".tool-button")["href"]).to eq(league_players_path(league))
    expect(section.text).not_to include(outsider.name)
    get league_players_path(league), params: { per_page: 5, sort: "alphabetical asc" }
    expect(response).to have_http_status(:ok)
    expect(document.css(".player-record").size).to eq(5)
    expect(document.css(".player-record").map { |row| row["id"] }).not_to include("player_#{outsider.id}")
    next_link = document.css("nav.pagy a[href]").find { |link| link["href"].include?("page=2") }
    expect(next_link).to be_present
    get next_link["href"]
    expect(response).to have_http_status(:ok)
    expect(document.css(".player-record").size).to eq(5)
    expect(document.at_css("body")["data-side"]).to eq("feed")
  end

  it "keeps nested league breadcrumbs and does not duplicate the title" do
    get sport_league_path(sport, league)
    expect(response).to have_http_status(:ok)
    expect(document.css("main h1").size).to eq(1)
    expect(document.css('nav[aria-label="Breadcrumb"] a').map { |link| link["href"] }).to eq([ sport_path(sport) ])
  end

  it "filters a season's competitions without mixing in games or other seasons" do
    competition = Contest.create! name: "Pacific playoffs", season: season, context: league, kind: "playoffs"
    other_season = create :season
    other = Contest.create! name: "Atlantic playoffs", season: other_season, context: other_season.league, kind: "playoffs"
    game = Game.create! name: "Pacific final", season: season, context: league
    get season_path(season)
    section = document.at_css(".related-section.contests")
    expect(section.text).to include(competition.name)
    expect(section.text).not_to include(game.name, other.name)
    get section.at_css(".tool-button")["href"]
    expect(response).to have_http_status(:ok)
    expect(document.css(".contest-item").map(&:text).join).to include(competition.name)
    expect(document.css(".contest-item").map(&:text).join).not_to include(game.name, other.name)
  end

  it "keeps the season and its champion as separate links" do
    season
    get seasons_path
    card = document.at_css(".season-item")
    expect(card.at_css("a.season-link")["href"]).to eq(season_path(season))
    expect(card.at_css(".season-champion-link")["href"]).to eq(team_path(team))
    expect(card.at_css(".season-link .season-champion-bank")).to be_nil
  end

  it "retains organization staff, dated affiliation history, external links and details" do
    organization = create :organization, name: "Pacific Sports Group"
    affiliation = create :organization_affiliation, organization: organization, team: team, details: { source: "Club archive" }
    person = create :person, name: "Avery Morgan"
    create :staff_tenure, person: person, organization: organization, role: :coach, title: "Head coach"
    get organization_path(organization)
    expect(response).to have_http_status(:ok)
    expect(document.css("main h1").map(&:text)).to eq([ organization.name ])
    expect(document.text).to include("Current Teams", "Affiliation History", person.name, "Head coach", "Present")
    expect(document.css("a").map { |link| link["href"] }).to include(person_path(person), organization_affiliation_path(affiliation), team_path(team), organization.url)
    get organization_affiliation_path(affiliation)
    expect(document.text).to include("Club archive", league.name, sport.name)
    expect(document.at_css("pre.browse-json")).to be_present
  end

  it "renders empty catalogs and missing metadata without dead sections" do
    [ organizations_path, organization_affiliations_path, memberships_path, federations_path, campaigns_path, contracts_path, activations_path, contests_path, games_path, seasons_path, years_path, achievements_path, spectrums_path ].each do |path|
      get path
      expect(response).to have_http_status(:ok), path
      expect(document.css("main h1").size).to eq(1), path
      expect(document.text).to include("No "), path
    end
    get stadium_path(stadium.tap { |venue| venue.update! capacity: nil, address: nil })
    expect(document.text).to include("Not recorded", "No teams recorded.", "No players recorded.")
    get season_path(season)
    expect(document.text).to include("No dates recorded.")
  end

  it "preserves content moderation visibility and admin-only editing" do
    achievement = create :achievement, name: "Read the defense"
    spectrum = create :spectrum, name: "Composure"
    pending = create :spectrum, name: "Private draft", created_by: create(:ace)
    get spectrums_path
    expect(document.text).to include(spectrum.name)
    expect(document.text).not_to include(pending.name, "New Spectrum")
    get spectrum_path(spectrum)
    expect(document.css("main h1").map(&:text)).to eq([ spectrum.name ])
    expect(document.css("main a").map { |link| link["href"] }).not_to include(edit_spectrum_path(spectrum))
    get achievement_path(achievement)
    expect(document.css("main a").map { |link| link["href"] }).not_to include(edit_achievement_path(achievement))
    sign_in create(:ace, :admin)
    get spectrum_path(spectrum), params: { side: "admin" }
    expect(document.at_css("body")["data-side"]).to eq("admin")
    expect(document.css("main a").map { |link| link["href"] }).to include(edit_spectrum_path(spectrum))
  end
end
