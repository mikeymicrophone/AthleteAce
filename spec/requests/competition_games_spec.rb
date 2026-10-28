require "rails_helper"

RSpec.describe "Competition and game pages", type: :request do
  it "links a competition, its format, title winner and shared game in the public catalog" do
    league = create(:league, name: "MLS")
    team = create(:team, league: league, territory: "Miami", mascot: "Inter")
    campaign = Campaign.create!(team: team, season: create(:season, league: league))
    contest = Contest.create!(name: "MLS Cup Playoffs", kind: "playoffs", context: league,
      format_rules: { "rounds" => [ { "key" => "final", "best_of" => 1 } ] })
    entry = Contestant.create!(contest: contest, campaign: campaign)
    game = Game.create!(name: "MLS Cup final", context: league, details: { "venue" => "Miami" })
    Contestant.create!(contest: game, campaign: campaign)
    ContestGame.create!(contest: contest, game: game, metadata: { "round" => "final", "source" => "Official fixture list" })
    TitleAward.create!(contest: contest, winner: entry, key: "mls_cup", name: "MLS Cup")
    get contest_path(contest)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Competition format", "Best of 1", "Titles awarded", "Miami Inter", game_path(game))
    get game_path(game)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("MLS Cup Playoffs", "Final", contest_path(contest))
    expect(Nokogiri::HTML(response.body).at_css(".back-link")["href"]).to eq(games_path)
    get contests_path
    expect(response.body).to include("MLS Cup Playoffs")
    expect(response.body).not_to include("MLS Cup final")
    get games_path
    expect(response.body).to include("MLS Cup final")
    expect(response.body).not_to include("MLS Cup Playoffs")
    get game_path(contest)
    expect(response).to have_http_status(:not_found)
  end
end
