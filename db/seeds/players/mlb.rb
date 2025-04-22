# MLB Teams - Player Rosters
# This file seeds players for all 30 MLB teams

mlb_teams = [
  { territory: "Los Angeles", mascot: "Dodgers", players: [
    { first_name: "Mookie", last_name: "Betts", nicknames: [], birthdate: "1992-10-07", current_position: "RF", debut_year: 2014, draft_year: 2011, active: true },
    { first_name: "Shohei", last_name: "Ohtani", nicknames: ["Showtime"], birthdate: "1994-07-05", current_position: "DH/P", debut_year: 2018, draft_year: 0, active: true },
    { first_name: "Freddie", last_name: "Freeman", nicknames: [], birthdate: "1989-09-12", current_position: "1B", debut_year: 2010, draft_year: 2007, active: true },
    { first_name: "Walker", last_name: "Buehler", nicknames: [], birthdate: "1994-07-28", current_position: "P", debut_year: 2017, draft_year: 2015, active: true }
    # Add more Dodgers players as needed
  ]},
  { territory: "New York", mascot: "Yankees", players: [
    { first_name: "Aaron", last_name: "Judge", nicknames: ["All Rise"], birthdate: "1992-04-26", current_position: "RF", debut_year: 2016, draft_year: 2013, active: true },
    { first_name: "Juan", last_name: "Soto", nicknames: ["Childish Bambino"], birthdate: "1998-10-25", current_position: "RF", debut_year: 2018, draft_year: 0, active: true },
    { first_name: "Gerrit", last_name: "Cole", nicknames: [], birthdate: "1990-09-08", current_position: "P", debut_year: 2013, draft_year: 2011, active: true }
    # Add more Yankees players as needed
  ]},
  { territory: "Houston", mascot: "Astros", players: [
    { first_name: "Jose", last_name: "Altuve", nicknames: ["Gigante"], birthdate: "1990-05-06", current_position: "2B", debut_year: 2011, draft_year: 0, active: true },
    { first_name: "Yordan", last_name: "Alvarez", nicknames: [], birthdate: "1997-06-27", current_position: "DH", debut_year: 2019, draft_year: 0, active: true },
    { first_name: "Justin", last_name: "Verlander", nicknames: ["JV"], birthdate: "1983-02-20", current_position: "P", debut_year: 2005, draft_year: 2004, active: true }
    # Add more Astros players as needed
  ]},
  { territory: "Atlanta", mascot: "Braves", players: [
    { first_name: "Ronald", last_name: "Acuna Jr.", nicknames: ["El Abusador"], birthdate: "1997-12-18", current_position: "RF", debut_year: 2018, draft_year: 0, active: true },
    { first_name: "Ozzie", last_name: "Albies", nicknames: ["Ozz"], birthdate: "1997-01-07", current_position: "2B", debut_year: 2017, draft_year: 0, active: true },
    { first_name: "Max", last_name: "Fried", nicknames: [], birthdate: "1994-01-18", current_position: "P", debut_year: 2017, draft_year: 2012, active: true }
    # Add more Braves players as needed
  ]},
  { territory: "Philadelphia", mascot: "Phillies", players: [
    { first_name: "Bryce", last_name: "Harper", nicknames: ["Harp"], birthdate: "1992-10-16", current_position: "1B", debut_year: 2012, draft_year: 2010, active: true },
    { first_name: "Trea", last_name: "Turner", nicknames: [], birthdate: "1993-06-30", current_position: "SS", debut_year: 2015, draft_year: 2014, active: true },
    { first_name: "Zack", last_name: "Wheeler", nicknames: [], birthdate: "1990-05-30", current_position: "P", debut_year: 2013, draft_year: 2009, active: true }
    # Add more Phillies players as needed
  ]},
  { territory: "San Diego", mascot: "Padres", players: [
    { first_name: "Manny", last_name: "Machado", nicknames: ["El Ministro"], birthdate: "1992-07-06", current_position: "3B", debut_year: 2012, draft_year: 2010, active: true },
    { first_name: "Fernando", last_name: "Tatis Jr.", nicknames: ["El Nino"], birthdate: "1999-01-02", current_position: "RF", debut_year: 2019, draft_year: 0, active: true },
    { first_name: "Yu", last_name: "Darvish", nicknames: [], birthdate: "1986-08-16", current_position: "P", debut_year: 2012, draft_year: 0, active: true }
    # Add more Padres players as needed
  ]},
  { territory: "Arizona", mascot: "Diamondbacks", players: [] },
  { territory: "Baltimore", mascot: "Orioles", players: [] },
  { territory: "Boston", mascot: "Red Sox", players: [] },
  { territory: "Chicago", mascot: "Cubs", players: [] },
  { territory: "Chicago", mascot: "White Sox", players: [] },
  { territory: "Cincinnati", mascot: "Reds", players: [] },
  { territory: "Cleveland", mascot: "Guardians", players: [] },
  { territory: "Colorado", mascot: "Rockies", players: [] },
  { territory: "Detroit", mascot: "Tigers", players: [] },
  { territory: "Kansas City", mascot: "Royals", players: [] },
  { territory: "Miami", mascot: "Marlins", players: [] },
  { territory: "Milwaukee", mascot: "Brewers", players: [] },
  { territory: "Minnesota", mascot: "Twins", players: [] },
  { territory: "New York", mascot: "Mets", players: [] },
  { territory: "Oakland", mascot: "Athletics", players: [] },
  { territory: "Pittsburgh", mascot: "Pirates", players: [] },
  { territory: "San Francisco", mascot: "Giants", players: [] },
  { territory: "Seattle", mascot: "Mariners", players: [] },
  { territory: "St. Louis", mascot: "Cardinals", players: [] },
  { territory: "Tampa Bay", mascot: "Rays", players: [] },
  { territory: "Texas", mascot: "Rangers", players: [] },
  { territory: "Toronto", mascot: "Blue Jays", players: [] },
  { territory: "Washington", mascot: "Nationals", players: [] }
]

mlb_teams.each do |team_data|
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
puts 'MLB team player seeding complete.'
