# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Seed sports
["Baseball", "Basketball", "Football", "Soccer", "Hockey", "Lacrosse", "Rugby", "Cricket"].each do |sport_name|
  Sport.find_or_create_by!(name: sport_name)
end

# Seed major leagues
leagues = [
  {
    name: "Major League Baseball",
    abbreviation: "MLB",
    sport_name: "Baseball",
    url: "https://www.mlb.com/",
    ios_app_url: "https://apps.apple.com/us/app/mlb/id493619333",
    year_of_origin: 1869,
    official_rules_url: "https://www.mlb.com/official-information/official-rules",
    logo_url: "https://upload.wikimedia.org/wikipedia/en/a/a6/Major_League_Baseball_logo.svg"
  },
  {
    name: "Major League Soccer",
    abbreviation: "MLS",
    sport_name: "Soccer",
    url: "https://www.mlssoccer.com/",
    ios_app_url: "https://apps.apple.com/us/app/mls-the-official-app/id397303467",
    year_of_origin: 1993,
    official_rules_url: "https://www.mlssoccer.com/about/roster-rules-and-regulations/",
    logo_url: "https://upload.wikimedia.org/wikipedia/en/6/6e/Major_League_Soccer_logo.svg"
  },
  {
    name: "National Basketball Association",
    abbreviation: "NBA",
    sport_name: "Basketball",
    url: "https://www.nba.com/",
    ios_app_url: "https://apps.apple.com/us/app/nba-live-games-scores/id335744614",
    year_of_origin: 1946,
    official_rules_url: "https://official.nba.com/rulebook/",
    logo_url: "https://upload.wikimedia.org/wikipedia/en/0/03/National_Basketball_Association_logo.svg"
  },
  {
    name: "National Hockey League",
    abbreviation: "NHL",
    sport_name: "Hockey",
    url: "https://www.nhl.com/",
    ios_app_url: "https://apps.apple.com/us/app/nhl/id465092669",
    year_of_origin: 1917,
    official_rules_url: "https://www.nhl.com/info/rules",
    logo_url: "https://upload.wikimedia.org/wikipedia/en/3/3a/05_NHL_Shield.svg"
  },
  {
    name: "National Football League",
    abbreviation: "NFL",
    sport_name: "Football",
    url: "https://www.nfl.com/",
    ios_app_url: "https://apps.apple.com/us/app/nfl/id389781154",
    year_of_origin: 1920,
    official_rules_url: "https://operations.nfl.com/the-rules/2023-nfl-rulebook/",
    logo_url: "https://upload.wikimedia.org/wikipedia/en/a/a2/National_Football_League_logo.svg"
  }
]

leagues.each do |league|
  sport = Sport.find_by(name: league[:sport_name])
  League.find_or_create_by!(
    name: league[:name],
    abbreviation: league[:abbreviation],
    sport: sport,
    url: league[:url],
    ios_app_url: league[:ios_app_url],
    year_of_origin: league[:year_of_origin],
    official_rules_url: league[:official_rules_url],
    logo_url: league[:logo_url]
  )
end
