require "rails_helper"

RSpec.describe "Player profiles", type: :request do
  let(:ace) { create(:ace) }
  let(:conference) { create(:conference) }
  let(:division) { create(:division, conference: conference) }
  let(:team) { create(:team, league: conference.league, primary_color: "#1450BE") }
  let(:player) { create(:player, team: team, current_position: "Pitcher", debut_year: "2020", active: true) }
  let!(:membership) { create(:membership, team: team, division: division) }
  let!(:spectrum) { create(:familiarity) }

  def document
    Nokogiri::HTML response.body
  end

  it "shows a public hero, hierarchy, real metadata and the team's quiz" do
    get player_path(player)

    expect(response).to have_http_status(:ok)
    expect(document.css("h1").map(&:text)).to eq([player.name])
    expect(document.at_css(".player-status-line").text).to eq("Pitcher · Active · Since 2020")
    expect(document.css(".player-breadcrumbs a span").map(&:text)).to eq([
      team.sport.name, team.league.name, conference.name, division.name, team.name
    ])
    expect(document.at_css(".profile-portrait")["style"]).to include("--jersey-color: #1450BE")
    expect(document.at_css(".player-hero .game-button")["href"]).to eq(new_game_round_path(team_id: team.id))
    expect(document.at_css(".rating-slider-input")["disabled"]).to be_present
    expect(document.at_css(".slider-value").text).to eq("Not rated")
    expect(document.at_css(".rating-summary").text).to include("No ratings yet")
    expect(document.at_css(".memory-stats")).to be_nil
  end

  it "preserves the filter's breadcrumb when opened through a team" do
    get team_player_path(team, player)

    expect(response).to have_http_status(:ok)
    expect(document.css(".player-breadcrumbs a span").map(&:text)).to eq([team.name])
    expect(document.at_css(".player-breadcrumbs [aria-current=page]").text).to eq(player.name)
  end

  it "keeps personal game history separate from other aces and players" do
    sign_in ace
    create(:game_attempt, ace: ace, subject_entity: player, is_correct: true)
    create(:game_attempt, ace: ace, subject_entity: player, is_correct: false, created_at: Time.zone.local(2026, 9, 30, 12))
    create(:game_attempt, subject_entity: player, is_correct: true)
    create(:game_attempt, ace: ace, is_correct: false)

    get player_path(player)

    expect(document.css(".memory-value").map(&:text)).to eq(["2", "50%", "Sep 30, 2026"])
    expect(document.at_css(".rating-slider-input")["disabled"]).to be_nil
  end

  it "shows unplayed history as zero seen and unknown accuracy" do
    sign_in ace
    get player_path(player)

    expect(document.css(".memory-value").map(&:text)).to eq(["0", "—", "—"])
    expect(response.body).to include("haven’t answered a question")
  end

  it "uses only seasons attached to the player's contracts and activations" do
    season = create(:season, league: team.league)
    other_season = create(:season, league: team.league)
    campaign = Campaign.create! team: team, season: season
    contract = create(:contract, player: player, team: team)
    create(:activation, contract: contract, campaign: campaign)

    get player_path(player)

    seasons = document.at_css("[aria-labelledby=player-seasons-title]")
    expect(seasons.css("a").map { |link| link["href"] }).to eq([season_path(season)])
    expect(seasons.text).not_to include(other_season.name)
  end

  it "does not treat a team color as arbitrary CSS or invent missing status" do
    team.update! primary_color: "red; background: url(https://example.com)"
    player.update! active: nil, debut_year: nil, current_position: nil

    get player_path(player)

    expect(document.at_css(".profile-portrait")["style"]).to be_nil
    expect(document.at_css(".player-status-line").text).to be_empty
  end
end
