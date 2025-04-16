# MLB Teams Seed
mlb = League.find_by(abbreviation: "MLB")
teams = [
  { territory: "Arizona", mascot: "Diamondbacks", abbreviation: "ARI", stadium_name: "Chase Field" },
  { territory: "Atlanta", mascot: "Braves", abbreviation: "ATL", stadium_name: "Truist Park" },
  { territory: "Baltimore", mascot: "Orioles", abbreviation: "BAL", stadium_name: "Oriole Park at Camden Yards" },
  { territory: "Boston", mascot: "Red Sox", abbreviation: "BOS", stadium_name: "Fenway Park" },
  { territory: "Chicago", mascot: "Cubs", abbreviation: "CHC", stadium_name: "Wrigley Field" },
  { territory: "Chicago", mascot: "White Sox", abbreviation: "CWS", stadium_name: "Guaranteed Rate Field" },
  { territory: "Cincinnati", mascot: "Reds", abbreviation: "CIN", stadium_name: "Great American Ball Park" },
  { territory: "Cleveland", mascot: "Guardians", abbreviation: "CLE", stadium_name: "Progressive Field" },
  { territory: "Colorado", mascot: "Rockies", abbreviation: "COL", stadium_name: "Coors Field" },
  { territory: "Detroit", mascot: "Tigers", abbreviation: "DET", stadium_name: "Comerica Park" },
  { territory: "Houston", mascot: "Astros", abbreviation: "HOU", stadium_name: "Minute Maid Park" },
  { territory: "Kansas City", mascot: "Royals", abbreviation: "KC", stadium_name: "Kauffman Stadium" },
  { territory: "Los Angeles", mascot: "Angels", abbreviation: "LAA", stadium_name: "Angel Stadium" },
  { territory: "Los Angeles", mascot: "Dodgers", abbreviation: "LAD", stadium_name: "Dodger Stadium" },
  { territory: "Miami", mascot: "Marlins", abbreviation: "MIA", stadium_name: "loanDepot park" },
  { territory: "Milwaukee", mascot: "Brewers", abbreviation: "MIL", stadium_name: "American Family Field" },
  { territory: "Minnesota", mascot: "Twins", abbreviation: "MIN", stadium_name: "Target Field" },
  { territory: "New York", mascot: "Mets", abbreviation: "NYM", stadium_name: "Citi Field" },
  { territory: "New York", mascot: "Yankees", abbreviation: "NYY", stadium_name: "Yankee Stadium" },
  { territory: "Oakland", mascot: "Athletics", abbreviation: "OAK", stadium_name: "Oakland Coliseum" },
  { territory: "Philadelphia", mascot: "Phillies", abbreviation: "PHI", stadium_name: "Citizens Bank Park" },
  { territory: "Pittsburgh", mascot: "Pirates", abbreviation: "PIT", stadium_name: "PNC Park" },
  { territory: "San Diego", mascot: "Padres", abbreviation: "SD", stadium_name: "Petco Park" },
  { territory: "San Francisco", mascot: "Giants", abbreviation: "SF", stadium_name: "Oracle Park" },
  { territory: "Seattle", mascot: "Mariners", abbreviation: "SEA", stadium_name: "T-Mobile Park" },
  { territory: "St. Louis", mascot: "Cardinals", abbreviation: "STL", stadium_name: "Busch Stadium" },
  { territory: "Tampa Bay", mascot: "Rays", abbreviation: "TB", stadium_name: "Tropicana Field" },
  { territory: "Texas", mascot: "Rangers", abbreviation: "TEX", stadium_name: "Globe Life Field" },
  { territory: "Toronto", mascot: "Blue Jays", abbreviation: "TOR", stadium_name: "Rogers Centre" },
  { territory: "Washington", mascot: "Nationals", abbreviation: "WSH", stadium_name: "Nationals Park" }
]
teams.each do |team|
  stadium = Stadium.find_by(name: team[:stadium_name])
  Team.find_or_create_by!(
    mascot: team[:mascot],
    territory: team[:territory],
    abbreviation: team[:abbreviation],
    league: mlb,
    stadium: stadium
  )
end
