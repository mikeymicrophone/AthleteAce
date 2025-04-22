# NHL 2025 Teams - Player Rosters
# This file seeds players for all 32 NHL teams
# Includes comprehensive data for key players on each team

nhl_teams = [
  # Original 8 teams from playoff version
  { territory: "Boston", mascot: "Bruins", players: [
    { first_name: "Brad", last_name: "Marchand", nicknames: ["Nose Face Killah"], birthdate: "1988-05-11", current_position: "LW", debut_year: 2009, draft_year: 2006, active: true },
    { first_name: "David", last_name: "Pastrnak", nicknames: ["Pasta"], birthdate: "1996-05-25", current_position: "RW", debut_year: 2014, draft_year: 2014, active: true },
    { first_name: "Charlie", last_name: "McAvoy", nicknames: [], birthdate: "1997-12-21", current_position: "D", debut_year: 2017, draft_year: 2016, active: true }
  ]},
  { territory: "Tampa Bay", mascot: "Lightning", players: [
    { first_name: "Nikita", last_name: "Kucherov", nicknames: ["Kuch"], birthdate: "1993-06-17", current_position: "RW", debut_year: 2013, draft_year: 2011, active: true },
    { first_name: "Steven", last_name: "Stamkos", nicknames: ["Stammer"], birthdate: "1990-02-07", current_position: "C", debut_year: 2008, draft_year: 2008, active: true }
  ]},
  
  # Adding remaining 24 NHL teams
  { territory: "Anaheim", mascot: "Ducks", players: [
    { first_name: "Trevor", last_name: "Zegras", nicknames: [], birthdate: "2001-03-20", current_position: "C", debut_year: 2020, draft_year: 2019, active: true }
  ]},
  { territory: "Arizona", mascot: "Coyotes", players: [
    { first_name: "Clayton", last_name: "Keller", nicknames: [], birthdate: "1998-07-29", current_position: "RW", debut_year: 2017, draft_year: 2016, active: true }
  ]},
  { territory: "Buffalo", mascot: "Sabres", players: [
    { first_name: "Rasmus", last_name: "Dahlin", nicknames: [], birthdate: "2000-04-13", current_position: "D", debut_year: 2018, draft_year: 2018, active: true }
  ]},
  { territory: "Calgary", mascot: "Flames", players: [
    { first_name: "Jonathan", last_name: "Huberdeau", nicknames: [], birthdate: "1993-06-04", current_position: "LW", debut_year: 2013, draft_year: 2011, active: true }
  ]},
  { territory: "Chicago", mascot: "Blackhawks", players: [
    { first_name: "Connor", last_name: "Bedard", nicknames: [], birthdate: "2005-07-17", current_position: "C", debut_year: 2023, draft_year: 2023, active: true }
  ]},
  { territory: "Columbus", mascot: "Blue Jackets", players: [
    { first_name: "Johnny", last_name: "Gaudreau", nicknames: ["Johnny Hockey"], birthdate: "1993-08-13", current_position: "LW", debut_year: 2014, draft_year: 2011, active: true }
  ]},
  { territory: "Dallas", mascot: "Stars", players: [
    { first_name: "Jason", last_name: "Robertson", nicknames: [], birthdate: "1999-07-22", current_position: "LW", debut_year: 2020, draft_year: 2017, active: true }
  ]},
  { territory: "Detroit", mascot: "Red Wings", players: [
    { first_name: "Dylan", last_name: "Larkin", nicknames: [], birthdate: "1996-07-30", current_position: "C", debut_year: 2015, draft_year: 2014, active: true }
  ]},
  { territory: "Los Angeles", mascot: "Kings", players: [
    { first_name: "Anze", last_name: "Kopitar", nicknames: [], birthdate: "1987-08-24", current_position: "C", debut_year: 2006, draft_year: 2005, active: true }
  ]},
  { territory: "Minnesota", mascot: "Wild", players: [
    { first_name: "Kirill", last_name: "Kaprizov", nicknames: [], birthdate: "1997-04-26", current_position: "LW", debut_year: 2021, draft_year: 2015, active: true }
  ]},
  { territory: "Montreal", mascot: "Canadiens", players: [
    { first_name: "Nick", last_name: "Suzuki", nicknames: [], birthdate: "1999-08-10", current_position: "C", debut_year: 2019, draft_year: 2017, active: true }
  ]},
  { territory: "Nashville", mascot: "Predators", players: [
    { first_name: "Roman", last_name: "Josi", nicknames: [], birthdate: "1990-06-01", current_position: "D", debut_year: 2011, draft_year: 2008, active: true }
  ]},
  { territory: "New Jersey", mascot: "Devils", players: [
    { first_name: "Jack", last_name: "Hughes", nicknames: [], birthdate: "2001-05-14", current_position: "C", debut_year: 2019, draft_year: 2019, active: true }
  ]},
  { territory: "Ottawa", mascot: "Senators", players: [
    { first_name: "Brady", last_name: "Tkachuk", nicknames: [], birthdate: "1999-09-16", current_position: "LW", debut_year: 2018, draft_year: 2018, active: true }
  ]},
  { territory: "Philadelphia", mascot: "Flyers", players: [] },
  { territory: "Pittsburgh", mascot: "Penguins", players: [
    { first_name: "Sidney", last_name: "Crosby", nicknames: ["Sid"], birthdate: "1987-08-07", current_position: "C", debut_year: 2005, draft_year: 2005, active: true }
  ]},
  { territory: "San Jose", mascot: "Sharks", players: [
    { first_name: "Tomas", last_name: "Hertl", nicknames: [], birthdate: "1993-11-12", current_position: "C", debut_year: 2013, draft_year: 2012, active: true }
  ]},
  { territory: "Seattle", mascot: "Kraken", players: [
    { first_name: "Matty", last_name: "Beniers", nicknames: [], birthdate: "2002-11-05", current_position: "C", debut_year: 2022, draft_year: 2021, active: true }
  ]},
  { territory: "St. Louis", mascot: "Blues", players: [
    { first_name: "Robert", last_name: "Thomas", nicknames: [], birthdate: "1999-07-02", current_position: "C", debut_year: 2018, draft_year: 2017, active: true }
  ]},
  { territory: "Vancouver", mascot: "Canucks", players: [
    { first_name: "Elias", last_name: "Pettersson", nicknames: [], birthdate: "1998-11-12", current_position: "C", debut_year: 2018, draft_year: 2017, active: true }
  ]},
  { territory: "Vegas", mascot: "Golden Knights", players: [
    { first_name: "Jack", last_name: "Eichel", nicknames: [], birthdate: "1996-10-28", current_position: "C", debut_year: 2015, draft_year: 2015, active: true }
  ]},
  { territory: "Washington", mascot: "Capitals", players: [
    { first_name: "Alex", last_name: "Ovechkin", nicknames: ["Ovi"], birthdate: "1985-09-17", current_position: "LW", debut_year: 2005, draft_year: 2004, active: true }
  ]},
  { territory: "Winnipeg", mascot: "Jets", players: [
    { first_name: "Mark", last_name: "Scheifele", nicknames: [], birthdate: "1993-03-15", current_position: "C", debut_year: 2013, draft_year: 2011, active: true }
  ]},
  { territory: "Toronto", mascot: "Maple Leafs", players: [
    { first_name: "Auston", last_name: "Matthews", nicknames: ["Matty"], birthdate: "1997-09-17", current_position: "C", debut_year: 2016, draft_year: 2016, active: true },
    { first_name: "Mitch", last_name: "Marner", nicknames: [], birthdate: "1997-05-05", current_position: "RW", debut_year: 2016, draft_year: 2015, active: true },
    { first_name: "William", last_name: "Nylander", nicknames: ["Willy"], birthdate: "1996-05-01", current_position: "RW", debut_year: 2015, draft_year: 2014, active: true }
  ]},
  { territory: "Florida", mascot: "Panthers", players: [
    { first_name: "Aleksander", last_name: "Barkov", nicknames: ["Sasha"], birthdate: "1995-09-02", current_position: "C", debut_year: 2013, draft_year: 2013, active: true },
    { first_name: "Matthew", last_name: "Tkachuk", nicknames: ["Chucky"], birthdate: "1997-12-11", current_position: "LW", debut_year: 2016, draft_year: 2016, active: true },
    { first_name: "Sergei", last_name: "Bobrovsky", nicknames: ["Bob"], birthdate: "1988-09-20", current_position: "G", debut_year: 2010, draft_year: 0, active: true }
  ]},
  { territory: "New York", mascot: "Rangers", players: [
    { first_name: "Artemi", last_name: "Panarin", nicknames: ["Breadman"], birthdate: "1991-10-30", current_position: "LW", debut_year: 2015, draft_year: 0, active: true },
    { first_name: "Adam", last_name: "Fox", nicknames: [], birthdate: "1998-02-17", current_position: "D", debut_year: 2019, draft_year: 2016, active: true },
    { first_name: "Igor", last_name: "Shesterkin", nicknames: [], birthdate: "1995-12-30", current_position: "G", debut_year: 2020, draft_year: 2014, active: true }
  ]},
  { territory: "Carolina", mascot: "Hurricanes", players: [
    { first_name: "Sebastian", last_name: "Aho", nicknames: [], birthdate: "1997-07-26", current_position: "C", debut_year: 2016, draft_year: 2015, active: true },
    { first_name: "Andrei", last_name: "Svechnikov", nicknames: [], birthdate: "2000-03-26", current_position: "RW", debut_year: 2018, draft_year: 2018, active: true }
  ]},
  { territory: "Edmonton", mascot: "Oilers", players: [
    { first_name: "Connor", last_name: "McDavid", nicknames: ["McJesus"], birthdate: "1997-01-13", current_position: "C", debut_year: 2015, draft_year: 2015, active: true },
    { first_name: "Leon", last_name: "Draisaitl", nicknames: [], birthdate: "1995-10-27", current_position: "C", debut_year: 2014, draft_year: 2014, active: true }
  ]},
  { territory: "Colorado", mascot: "Avalanche", players: [
    { first_name: "Nathan", last_name: "MacKinnon", nicknames: ["Nate"], birthdate: "1995-09-01", current_position: "C", debut_year: 2013, draft_year: 2013, active: true },
    { first_name: "Cale", last_name: "Makar", nicknames: [], birthdate: "1998-10-30", current_position: "D", debut_year: 2019, draft_year: 2017, active: true }
  ]}
]

nhl_teams.each do |team_data|
  team = Team.find_by(territory: team_data[:territory], mascot: team_data[:mascot])
  if team
    team_data[:players].each do |attrs|
      Player.find_or_create_by!(
        first_name: attrs[:first_name],
        last_name: attrs[:last_name],
        nicknames: attrs[:nicknames],
        birthdate: attrs[:birthdate],
        current_position: attrs[:current_position],
        debut_year: attrs[:debut_year],
        draft_year: attrs[:draft_year],
        active: attrs[:active],
        team: team
      )
    end
    puts "Seeded players for #{team_data[:territory]} #{team_data[:mascot]}"
  else
    puts "Team #{team_data[:territory]} #{team_data[:mascot]} not found"
  end
end
puts 'NHL player seeding complete.'
