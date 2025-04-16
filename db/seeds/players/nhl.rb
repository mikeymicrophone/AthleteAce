# NHL 2025 Playoff Teams - Player Rosters
# This file seeds players for NHL playoff teams (as of the 2025 playoffs)
# Includes comprehensive data for key teams, with structure to expand for others.

nhl_playoff_teams = [
  { territory: "Boston", mascot: "Bruins", players: [
    { first_name: "Brad", last_name: "Marchand", nicknames: ["Nose Face Killah"], birthdate: "1988-05-11", jersey_number: 63, current_position: "LW", height_in: 69, weight_lb: 181, debut_year: 2009, draft_year: 2006, active: true },
    { first_name: "David", last_name: "Pastrnak", nicknames: ["Pasta"], birthdate: "1996-05-25", jersey_number: 88, current_position: "RW", height_in: 72, weight_lb: 195, debut_year: 2014, draft_year: 2014, active: true },
    { first_name: "Charlie", last_name: "McAvoy", nicknames: [], birthdate: "1997-12-21", jersey_number: 73, current_position: "D", height_in: 73, weight_lb: 209, debut_year: 2017, draft_year: 2016, active: true },
    { first_name: "Jeremy", last_name: "Swayman", nicknames: [], birthdate: "1998-11-24", jersey_number: 1, current_position: "G", height_in: 75, weight_lb: 195, debut_year: 2021, draft_year: 2017, active: true }
    # Add more Bruins players as needed
  ]},
  { territory: "Tampa Bay", mascot: "Lightning", players: [
    { first_name: "Nikita", last_name: "Kucherov", nicknames: ["Kuch"], birthdate: "1993-06-17", jersey_number: 86, current_position: "RW", height_in: 71, weight_lb: 183, debut_year: 2013, draft_year: 2011, active: true },
    { first_name: "Steven", last_name: "Stamkos", nicknames: ["Stammer"], birthdate: "1990-02-07", jersey_number: 91, current_position: "C", height_in: 73, weight_lb: 182, debut_year: 2008, draft_year: 2008, active: true },
    { first_name: "Victor", last_name: "Hedman", nicknames: [], birthdate: "1990-12-18", jersey_number: 77, current_position: "D", height_in: 78, weight_lb: 241, debut_year: 2009, draft_year: 2009, active: true },
    { first_name: "Andrei", last_name: "Vasilevskiy", nicknames: ["Big Cat"], birthdate: "1994-07-25", jersey_number: 88, current_position: "G", height_in: 76, weight_lb: 225, debut_year: 2014, draft_year: 2012, active: true }
    # Add more Lightning players as needed
  ]},
  { territory: "Toronto", mascot: "Maple Leafs", players: [
    { first_name: "Auston", last_name: "Matthews", nicknames: ["Matty"], birthdate: "1997-09-17", jersey_number: 34, current_position: "C", height_in: 75, weight_lb: 215, debut_year: 2016, draft_year: 2016, active: true },
    { first_name: "Mitch", last_name: "Marner", nicknames: [], birthdate: "1997-05-05", jersey_number: 16, current_position: "RW", height_in: 72, weight_lb: 181, debut_year: 2016, draft_year: 2015, active: true },
    { first_name: "William", last_name: "Nylander", nicknames: ["Willy"], birthdate: "1996-05-01", jersey_number: 88, current_position: "RW", height_in: 72, weight_lb: 204, debut_year: 2015, draft_year: 2014, active: true }
    # Add more Maple Leafs players as needed
  ]},
  { territory: "Florida", mascot: "Panthers", players: [
    { first_name: "Aleksander", last_name: "Barkov", nicknames: ["Sasha"], birthdate: "1995-09-02", jersey_number: 16, current_position: "C", height_in: 75, weight_lb: 215, debut_year: 2013, draft_year: 2013, active: true },
    { first_name: "Matthew", last_name: "Tkachuk", nicknames: ["Chucky"], birthdate: "1997-12-11", jersey_number: 19, current_position: "LW", height_in: 74, weight_lb: 202, debut_year: 2016, draft_year: 2016, active: true },
    { first_name: "Sergei", last_name: "Bobrovsky", nicknames: ["Bob"], birthdate: "1988-09-20", jersey_number: 72, current_position: "G", height_in: 74, weight_lb: 187, debut_year: 2010, draft_year: 0, active: true }
    # Add more Panthers players as needed
  ]},
  { territory: "New York", mascot: "Rangers", players: [
    { first_name: "Artemi", last_name: "Panarin", nicknames: ["Breadman"], birthdate: "1991-10-30", jersey_number: 10, current_position: "LW", height_in: 72, weight_lb: 175, debut_year: 2015, draft_year: 0, active: true },
    { first_name: "Adam", last_name: "Fox", nicknames: [], birthdate: "1998-02-17", jersey_number: 23, current_position: "D", height_in: 71, weight_lb: 183, debut_year: 2019, draft_year: 2016, active: true },
    { first_name: "Igor", last_name: "Shesterkin", nicknames: [], birthdate: "1995-12-30", jersey_number: 31, current_position: "G", height_in: 73, weight_lb: 189, debut_year: 2020, draft_year: 2014, active: true }
    # Add more Rangers players as needed
  ]},
  { territory: "Carolina", mascot: "Hurricanes", players: [
    { first_name: "Sebastian", last_name: "Aho", nicknames: [], birthdate: "1997-07-26", jersey_number: 20, current_position: "C", height_in: 72, weight_lb: 176, debut_year: 2016, draft_year: 2015, active: true },
    { first_name: "Andrei", last_name: "Svechnikov", nicknames: [], birthdate: "2000-03-26", jersey_number: 37, current_position: "RW", height_in: 74, weight_lb: 195, debut_year: 2018, draft_year: 2018, active: true }
    # Add more Hurricanes players as needed
  ]},
  { territory: "Edmonton", mascot: "Oilers", players: [
    { first_name: "Connor", last_name: "McDavid", nicknames: ["McJesus"], birthdate: "1997-01-13", jersey_number: 97, current_position: "C", height_in: 73, weight_lb: 193, debut_year: 2015, draft_year: 2015, active: true },
    { first_name: "Leon", last_name: "Draisaitl", nicknames: [], birthdate: "1995-10-27", jersey_number: 29, current_position: "C", height_in: 74, weight_lb: 208, debut_year: 2014, draft_year: 2014, active: true }
    # Add more Oilers players as needed
  ]},
  { territory: "Colorado", mascot: "Avalanche", players: [
    { first_name: "Nathan", last_name: "MacKinnon", nicknames: ["Nate"], birthdate: "1995-09-01", jersey_number: 29, current_position: "C", height_in: 72, weight_lb: 200, debut_year: 2013, draft_year: 2013, active: true },
    { first_name: "Cale", last_name: "Makar", nicknames: [], birthdate: "1998-10-30", jersey_number: 8, current_position: "D", height_in: 71, weight_lb: 187, debut_year: 2019, draft_year: 2017, active: true }
    # Add more Avalanche players as needed
  ]}
  # Additional playoff teams can be added here (e.g., Vancouver Canucks, Dallas Stars, etc.)
]

nhl_playoff_teams.each do |team_data|
  team = Team.find_by(territory: team_data[:territory], mascot: team_data[:mascot])
  if team
    team_data[:players].each do |attrs|
      Player.find_or_create_by!(
        first_name: attrs[:first_name],
        last_name: attrs[:last_name],
        nicknames: attrs[:nicknames],
        birthdate: attrs[:birthdate],
        jersey_number: attrs[:jersey_number],
        current_position: attrs[:current_position],
        height_in: attrs[:height_in],
        weight_lb: attrs[:weight_lb],
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
puts 'NHL playoff player seeding complete.'
