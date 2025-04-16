# NHL Teams Seed
nhl = League.find_by(abbreviation: "NHL")
teams = [
  { territory: "Anaheim", mascot: "Ducks", abbreviation: "ANA", stadium_name: "Honda Center" },
  { territory: "Arizona", mascot: "Coyotes", abbreviation: "ARI", stadium_name: "Mullett Arena" },
  { territory: "Boston", mascot: "Bruins", abbreviation: "BOS", stadium_name: "TD Garden" },
  { territory: "Buffalo", mascot: "Sabres", abbreviation: "BUF", stadium_name: "KeyBank Center" },
  { territory: "Calgary", mascot: "Flames", abbreviation: "CGY", stadium_name: "Scotiabank Saddledome" },
  { territory: "Carolina", mascot: "Hurricanes", abbreviation: "CAR", stadium_name: "PNC Arena" },
  { territory: "Chicago", mascot: "Blackhawks", abbreviation: "CHI", stadium_name: "United Center" },
  { territory: "Colorado", mascot: "Avalanche", abbreviation: "COL", stadium_name: "Ball Arena" },
  { territory: "Columbus", mascot: "Blue Jackets", abbreviation: "CBJ", stadium_name: "Nationwide Arena" },
  { territory: "Dallas", mascot: "Stars", abbreviation: "DAL", stadium_name: "American Airlines Center" },
  { territory: "Detroit", mascot: "Red Wings", abbreviation: "DET", stadium_name: "Little Caesars Arena" },
  { territory: "Edmonton", mascot: "Oilers", abbreviation: "EDM", stadium_name: "Rogers Place" },
  { territory: "Florida", mascot: "Panthers", abbreviation: "FLA", stadium_name: "Amerant Bank Arena" },
  { territory: "Los Angeles", mascot: "Kings", abbreviation: "LAK", stadium_name: "Crypto.com Arena" },
  { territory: "Minnesota", mascot: "Wild", abbreviation: "MIN", stadium_name: "Xcel Energy Center" },
  { territory: "Montreal", mascot: "Canadiens", abbreviation: "MTL", stadium_name: "Bell Centre" },
  { territory: "Nashville", mascot: "Predators", abbreviation: "NSH", stadium_name: "Bridgestone Arena" },
  { territory: "New Jersey", mascot: "Devils", abbreviation: "NJD", stadium_name: "Prudential Center" },
  { territory: "NY Islanders", mascot: "Islanders", abbreviation: "NYI", stadium_name: "UBS Arena" },
  { territory: "NY Rangers", mascot: "Rangers", abbreviation: "NYR", stadium_name: "Madison Square Garden" },
  { territory: "Ottawa", mascot: "Senators", abbreviation: "OTT", stadium_name: "Canadian Tire Centre" },
  { territory: "Philadelphia", mascot: "Flyers", abbreviation: "PHI", stadium_name: "Wells Fargo Center" },
  { territory: "Pittsburgh", mascot: "Penguins", abbreviation: "PIT", stadium_name: "PPG Paints Arena" },
  { territory: "San Jose", mascot: "Sharks", abbreviation: "SJS", stadium_name: "SAP Center" },
  { territory: "Seattle", mascot: "Kraken", abbreviation: "SEA", stadium_name: "Climate Pledge Arena" },
  { territory: "St. Louis", mascot: "Blues", abbreviation: "STL", stadium_name: "Enterprise Center" },
  { territory: "Tampa Bay", mascot: "Lightning", abbreviation: "TBL", stadium_name: "Amalie Arena" },
  { territory: "Toronto", mascot: "Maple Leafs", abbreviation: "TOR", stadium_name: "Scotiabank Arena" },
  { territory: "Vancouver", mascot: "Canucks", abbreviation: "VAN", stadium_name: "Rogers Arena" },
  { territory: "Vegas", mascot: "Golden Knights", abbreviation: "VGK", stadium_name: "T-Mobile Arena" },
  { territory: "Washington", mascot: "Capitals", abbreviation: "WSH", stadium_name: "Capital One Arena" },
  { territory: "Winnipeg", mascot: "Jets", abbreviation: "WPG", stadium_name: "Canada Life Centre" }
]
teams.each do |team|
  stadium = Stadium.find_by(name: team[:stadium_name])
  Team.find_or_create_by!(
    mascot: team[:mascot],
    territory: team[:territory],
    abbreviation: team[:abbreviation],
    league: nhl,
    stadium: stadium
  )
end
