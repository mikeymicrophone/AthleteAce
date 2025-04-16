# Seeds for Leagues and Stadia

# Leagues (example, assumes sports already seeded)
leagues = [
  { name: "Major League Baseball", abbreviation: "MLB", sport_name: "Baseball" },
  { name: "National Football League", abbreviation: "NFL", sport_name: "Football" }
]
leagues.each do |league|
  sport = Sport.find_by(name: league[:sport_name])
  League.find_or_create_by!(name: league[:name], abbreviation: league[:abbreviation], sport: sport)
end

# Stadia (example, assumes cities already seeded)
yankee_stadium_city = City.find_by(name: "New York City")
Stadium.find_or_create_by!(name: "Yankee Stadium", city: yankee_stadium_city, capacity: 47309, opened_year: 2009, url: "https://www.mlb.com/yankees/ballpark", address: "1 E 161 St, Bronx, NY 10451")
