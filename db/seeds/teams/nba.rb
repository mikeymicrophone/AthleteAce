# NBA Teams Seed
nba = League.find_by(abbreviation: "NBA")
teams = [
  { territory: "Atlanta", mascot: "Hawks", abbreviation: "ATL", stadium_name: "State Farm Arena" },
  { territory: "Boston", mascot: "Celtics", abbreviation: "BOS", stadium_name: "TD Garden" },
  { territory: "Brooklyn", mascot: "Nets", abbreviation: "BKN", stadium_name: "Barclays Center" },
  { territory: "Charlotte", mascot: "Hornets", abbreviation: "CHA", stadium_name: "Spectrum Center" },
  { territory: "Chicago", mascot: "Bulls", abbreviation: "CHI", stadium_name: "United Center" },
  { territory: "Cleveland", mascot: "Cavaliers", abbreviation: "CLE", stadium_name: "Rocket Mortgage FieldHouse" },
  { territory: "Dallas", mascot: "Mavericks", abbreviation: "DAL", stadium_name: "American Airlines Center" },
  { territory: "Denver", mascot: "Nuggets", abbreviation: "DEN", stadium_name: "Ball Arena" },
  { territory: "Detroit", mascot: "Pistons", abbreviation: "DET", stadium_name: "Little Caesars Arena" },
  { territory: "Golden State", mascot: "Warriors", abbreviation: "GSW", stadium_name: "Chase Center" },
  { territory: "Houston", mascot: "Rockets", abbreviation: "HOU", stadium_name: "Toyota Center" },
  { territory: "Indiana", mascot: "Pacers", abbreviation: "IND", stadium_name: "Gainbridge Fieldhouse" },
  { territory: "LA Clippers", mascot: "Clippers", abbreviation: "LAC", stadium_name: "Crypto.com Arena" },
  { territory: "Los Angeles", mascot: "Lakers", abbreviation: "LAL", stadium_name: "Crypto.com Arena" },
  { territory: "Memphis", mascot: "Grizzlies", abbreviation: "MEM", stadium_name: "FedExForum" },
  { territory: "Miami", mascot: "Heat", abbreviation: "MIA", stadium_name: "Kaseya Center" },
  { territory: "Milwaukee", mascot: "Bucks", abbreviation: "MIL", stadium_name: "Fiserv Forum" },
  { territory: "Minnesota", mascot: "Timberwolves", abbreviation: "MIN", stadium_name: "Target Center" },
  { territory: "New Orleans", mascot: "Pelicans", abbreviation: "NOP", stadium_name: "Smoothie King Center" },
  { territory: "New York", mascot: "Knicks", abbreviation: "NYK", stadium_name: "Madison Square Garden" },
  { territory: "Oklahoma City", mascot: "Thunder", abbreviation: "OKC", stadium_name: "Paycom Center" },
  { territory: "Orlando", mascot: "Magic", abbreviation: "ORL", stadium_name: "Kia Center" },
  { territory: "Philadelphia", mascot: "76ers", abbreviation: "PHI", stadium_name: "Wells Fargo Center" },
  { territory: "Phoenix", mascot: "Suns", abbreviation: "PHX", stadium_name: "Footprint Center" },
  { territory: "Portland", mascot: "Trail Blazers", abbreviation: "POR", stadium_name: "Moda Center" },
  { territory: "Sacramento", mascot: "Kings", abbreviation: "SAC", stadium_name: "Golden 1 Center" },
  { territory: "San Antonio", mascot: "Spurs", abbreviation: "SAS", stadium_name: "Frost Bank Center" },
  { territory: "Toronto", mascot: "Raptors", abbreviation: "TOR", stadium_name: "Scotiabank Arena" },
  { territory: "Utah", mascot: "Jazz", abbreviation: "UTA", stadium_name: "Delta Center" },
  { territory: "Washington", mascot: "Wizards", abbreviation: "WAS", stadium_name: "Capital One Arena" }
]
teams.each do |team|
  stadium = Stadium.find_by(name: team[:stadium_name])
  Team.find_or_create_by!(
    mascot: team[:mascot],
    territory: team[:territory],
    abbreviation: team[:abbreviation],
    league: nba,
    stadium: stadium
  )
end
