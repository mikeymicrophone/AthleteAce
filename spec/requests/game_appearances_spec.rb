require "rails_helper"

RSpec.describe "Game appearances", type: :request do
  it "displays named context, winner, and sourced player statistics with unknown starter status" do
    league = create :nba
    team = create :team, league: league
    player = create :player, team: nil, sport: league.sport
    campaign = Campaign.create! team: team, season: create(:season, league: league)
    game = Contest.create! kind: "game", context: league, champion: team, name: "Example game"
    contestant = Contestant.create! contest: game, campaign: campaign
    Appearance.create! player: player, contestant: contestant, jersey_number: "00", statistics: { "points" => 0, "time_on_ice" => "20:50" }

    get contest_path(game)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(league_path(league), team_path(team), player_path(player))
    document = Nokogiri::HTML(response.body)
    expect(document.at_css(".contest-appearances").text).to include(player.name, team.name, "00", "Starter", "Unknown", "Points", "0", "Time on ice", "20:50")
    expect(response.body).not_to include("Champion ID:", "#&lt;League")
  end

  it "does not manufacture an appearances section for an aggregate contest" do
    contest = Contest.create! context: create(:league), kind: "series"
    get contest_path(contest)
    expect(response).to have_http_status(:ok)
    expect(Nokogiri::HTML(response.body).css(".contest-appearances")).to be_empty
  end
end
