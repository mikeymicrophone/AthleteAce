# MLB 2025 Playoff Teams - Player Rosters
# This file seeds players for MLB playoff teams (or top teams as of 2025 season)
# Includes comprehensive data for key teams, with structure to expand for others.

mlb_playoff_teams = [
  { territory: "Los Angeles", mascot: "Dodgers", players: [
    { first_name: "Mookie", last_name: "Betts", nicknames: [], birthdate: "1992-10-07", jersey_number: 50, current_position: "RF", height_in: 69, weight_lb: 180, debut_year: 2014, draft_year: 2011, active: true },
    { first_name: "Shohei", last_name: "Ohtani", nicknames: ["Showtime"], birthdate: "1994-07-05", jersey_number: 17, current_position: "DH/P", height_in: 76, weight_lb: 210, debut_year: 2018, draft_year: 0, active: true },
    { first_name: "Freddie", last_name: "Freeman", nicknames: [], birthdate: "1989-09-12", jersey_number: 5, current_position: "1B", height_in: 77, weight_lb: 220, debut_year: 2010, draft_year: 2007, active: true },
    { first_name: "Walker", last_name: "Buehler", nicknames: [], birthdate: "1994-07-28", jersey_number: 21, current_position: "P", height_in: 74, weight_lb: 185, debut_year: 2017, draft_year: 2015, active: true }
    # Add more Dodgers players as needed
  ]},
  { territory: "New York", mascot: "Yankees", players: [
    { first_name: "Aaron", last_name: "Judge", nicknames: ["All Rise"], birthdate: "1992-04-26", jersey_number: 99, current_position: "RF", height_in: 79, weight_lb: 282, debut_year: 2016, draft_year: 2013, active: true },
    { first_name: "Juan", last_name: "Soto", nicknames: ["Childish Bambino"], birthdate: "1998-10-25", jersey_number: 22, current_position: "RF", height_in: 74, weight_lb: 224, debut_year: 2018, draft_year: 0, active: true },
    { first_name: "Gerrit", last_name: "Cole", nicknames: [], birthdate: "1990-09-08", jersey_number: 45, current_position: "P", height_in: 76, weight_lb: 220, debut_year: 2013, draft_year: 2011, active: true }
    # Add more Yankees players as needed
  ]},
  { territory: "Houston", mascot: "Astros", players: [
    { first_name: "Jose", last_name: "Altuve", nicknames: ["Gigante"], birthdate: "1990-05-06", jersey_number: 27, current_position: "2B", height_in: 66, weight_lb: 166, debut_year: 2011, draft_year: 0, active: true },
    { first_name: "Yordan", last_name: "Alvarez", nicknames: [], birthdate: "1997-06-27", jersey_number: 44, current_position: "DH", height_in: 77, weight_lb: 225, debut_year: 2019, draft_year: 0, active: true },
    { first_name: "Justin", last_name: "Verlander", nicknames: ["JV"], birthdate: "1983-02-20", jersey_number: 35, current_position: "P", height_in: 77, weight_lb: 235, debut_year: 2005, draft_year: 2004, active: true }
    # Add more Astros players as needed
  ]},
  { territory: "Atlanta", mascot: "Braves", players: [
    { first_name: "Ronald", last_name: "Acuna Jr.", nicknames: ["El Abusador"], birthdate: "1997-12-18", jersey_number: 13, current_position: "RF", height_in: 72, weight_lb: 205, debut_year: 2018, draft_year: 0, active: true },
    { first_name: "Ozzie", last_name: "Albies", nicknames: ["Ozz"], birthdate: "1997-01-07", jersey_number: 1, current_position: "2B", height_in: 68, weight_lb: 165, debut_year: 2017, draft_year: 0, active: true },
    { first_name: "Max", last_name: "Fried", nicknames: [], birthdate: "1994-01-18", jersey_number: 54, current_position: "P", height_in: 76, weight_lb: 190, debut_year: 2017, draft_year: 2012, active: true }
    # Add more Braves players as needed
  ]},
  { territory: "Philadelphia", mascot: "Phillies", players: [
    { first_name: "Bryce", last_name: "Harper", nicknames: ["Harp"], birthdate: "1992-10-16", jersey_number: 3, current_position: "1B", height_in: 75, weight_lb: 210, debut_year: 2012, draft_year: 2010, active: true },
    { first_name: "Trea", last_name: "Turner", nicknames: [], birthdate: "1993-06-30", jersey_number: 7, current_position: "SS", height_in: 74, weight_lb: 185, debut_year: 2015, draft_year: 2014, active: true },
    { first_name: "Zack", last_name: "Wheeler", nicknames: [], birthdate: "1990-05-30", jersey_number: 45, current_position: "P", height_in: 76, weight_lb: 195, debut_year: 2013, draft_year: 2009, active: true }
    # Add more Phillies players as needed
  ]},
  { territory: "San Diego", mascot: "Padres", players: [
    { first_name: "Manny", last_name: "Machado", nicknames: ["El Ministro"], birthdate: "1992-07-06", jersey_number: 13, current_position: "3B", height_in: 75, weight_lb: 218, debut_year: 2012, draft_year: 2010, active: true },
    { first_name: "Fernando", last_name: "Tatis Jr.", nicknames: ["El Nino"], birthdate: "1999-01-02", jersey_number: 23, current_position: "RF", height_in: 75, weight_lb: 217, debut_year: 2019, draft_year: 0, active: true },
    { first_name: "Yu", last_name: "Darvish", nicknames: [], birthdate: "1986-08-16", jersey_number: 11, current_position: "P", height_in: 77, weight_lb: 220, debut_year: 2012, draft_year: 0, active: true }
    # Add more Padres players as needed
  ]}
  # Additional playoff teams can be added here (e.g., Texas Rangers, Baltimore Orioles, etc.)
]

mlb_playoff_teams.each do |team_data|
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
puts 'MLB playoff player seeding complete.'
