# AthleteAce Database Seed File
# This file loads data from the athlete_ace_data source directory

puts "===== Seeding AthleteAce Database ====="

# Step 1: Load sports data
puts "\n----- Seeding Sports -----"
sports_file = File.read(Rails.root.join('db/seeds/athlete_ace_data/sports/sports.json'))
sports = JSON.parse(sports_file)

sports.each do |sport_name|
  sport = Sport.find_or_initialize_by(name: sport_name)
  sport.save!
  puts "Created sport: #{sport_name}"
end

# Step 2: Load location data
puts "\n----- Seeding Locations -----"

# Countries
puts "Loading countries..."
Dir.glob(Rails.root.join('db/seeds/athlete_ace_data/locations/countries/*.json')).each do |file|
  countries_file = File.read(file)
  countries = JSON.parse(countries_file)
  countries.each do |country|
    country_record = Country.find_or_initialize_by(name: country["name"])
    country_record.save!
    puts "Created country: #{country['name']}"
  end
end

# States
puts "Loading states..."
Dir.glob(Rails.root.join('db/seeds/athlete_ace_data/locations/states/*.json')).each do |file|
  states_file = File.read(file)
  states = JSON.parse(states_file)
  country = Country.find_by(name: states["country_name"])
  states["states"].each do |state|
    state_record = State.find_or_initialize_by(
      name: state["name"],
      abbreviation: state["abbreviation"]
    )
    state_record.country = country
    state_record.save!
    puts "Created state: #{state['name']}"
  end
end

# Cities
puts "Loading cities..."
Dir.glob(Rails.root.join('db/seeds/athlete_ace_data/locations/cities/*.json')).each do |file|
  cities_file = File.read(file)
  cities = JSON.parse(cities_file)
  country = Country.find_by(name: cities["country_name"])
  
  cities["cities"].each do |city|
    # Find state by abbreviation
    state = State.find_by(abbreviation: city["state"], country: country)
    
    if state
      city_record = City.find_or_initialize_by(
        name: city["name"]
      )
      city_record.state = state
      city_record.save!
      puts "Created city: #{city['name']}, #{state.abbreviation}"
    else
      puts "Warning: Could not find state with abbreviation #{city['state']} in #{cities['country_name']}"
    end
  end
end

# Step 3: Load stadiums data
puts "\n----- Seeding Stadiums -----"
Dir.glob(Rails.root.join('db/seeds/athlete_ace_data/locations/stadiums/*.json')).each do |file|
  stadiums_file = File.read(file)
  stadiums = JSON.parse(stadiums_file)
  country = Country.find_by(name: stadiums["country_name"])
  
  stadiums["stadiums"].each do |stadium|
    # Find the state by name
    state_name = stadium["state_name"]
    state = State.find_by("name LIKE ?", "%#{state_name}%")
    
    # Find the city by name and state
    city = nil
    if state
      city = City.find_by(name: stadium["city_name"], state: state)
    end
    
    # If city not found, try to find by name only
    if city.nil?
      city = City.find_by(name: stadium["city_name"])
    end
    
    if city
      # Create the stadium
      stadium_record = Stadium.find_or_initialize_by(name: stadium["name"])
      stadium_record.assign_attributes(
        city: city,
        capacity: stadium["capacity"],
        opened_year: stadium["opened_year"],
        address: stadium["address"],
        url: stadium["url"]
      )
      stadium_record.save!
      
      puts "Created stadium: #{stadium['name']} in #{city.name}, #{city.state.abbreviation}"
    else
      puts "Warning: Could not find city #{stadium['city_name']} in #{stadium['state_name']}"
    end
  end
end

# Step 4: Load leagues data
puts "\n----- Seeding Leagues -----"
Dir.glob(Rails.root.join('db/seeds/athlete_ace_data/sports/*/leagues.json')).each do |file|
  leagues_file = File.read(file)
  leagues = JSON.parse(leagues_file)
  sport = Sport.find_by(name: leagues["sport_name"])
  leagues["leagues"].each do |league|
    league_record = League.find_or_initialize_by(
      name: league["name"]
    )
    league_record.assign_attributes(
      abbreviation: league["abbreviation"],
      sport: sport,
      url: league["url"],
      year_of_origin: league["year_of_origin"],
      official_rules_url: league["official_rules_url"],
      logo_url: league["logo_url"]
    )
    league_record.save!
    puts "Created league: #{league['name']}"
  end
end

# Step 5: Load teams data
puts "\n----- Seeding Teams -----"
Dir.glob(Rails.root.join('db/seeds/athlete_ace_data/sports/**/teams.json')).each do |file|
  teams_file = File.read(file)
  teams = JSON.parse(teams_file)
  league = League.find_by(name: teams["league_name"])
  teams["teams"].each do |team|
    stadium = Stadium.find_by(name: team["stadium_name"])
    
    # Remove keys that aren't attributes but references to other objects
    team_attributes = team.except("stadium_name")
    
    # Find or initialize the team
    team_record = Team.find_or_initialize_by(
      mascot: team["mascot"],
      territory: team["territory"]
    )
    
    # Assign all attributes from JSON
    team_record.assign_attributes(team_attributes)
    team_record.league = league
    team_record.stadium = stadium
    team_record.save!
    
    puts "Created team: #{team['territory']} #{team['mascot']}"
  end
end

# Step 6: Load players data
puts "\n----- Seeding Players -----"
Dir.glob(Rails.root.join('db/seeds/athlete_ace_data/sports/**/players/*.json')).each do |file|
  players_file = File.read(file)
  players = JSON.parse(players_file)
  team = Team.find_by(mascot: players["team_name"])
  
  next unless team # Skip if team not found
  
  players["players"].each do |player|
    # Find or initialize the player
    player_record = Player.find_or_initialize_by(
      first_name: player["first_name"],
      last_name: player["last_name"],
      team: team
    )
    
    # Assign all attributes from JSON
    player_record.assign_attributes(
      current_position: player["current_position"],
      birthdate: player["birthdate"],
      debut_year: player["debut_year"],
      draft_year: player["draft_year"],
      active: player["active"],
      nicknames: player["nicknames"],
      bio: player["bio"],
      photo_urls: player["photo_urls"]
    )
    
    player_record.save!
    puts "Created/updated player: #{player['first_name']} #{player['last_name']}"
  end
end

# Step 7: Create sport positions
puts "\n----- Creating Sport Positions -----"

# Define position creation helper method
def create_sport_positions(sport_name)
  sport = Sport.find_by(name: sport_name)
  return unless sport
  
  # Load positions from JSON file
  positions_file = Rails.root.join('db', 'seeds', 'athlete_ace_data', 'sports', 'positions', "#{sport_name.downcase}.json")
  return unless File.exist?(positions_file)
  
  positions_data = JSON.parse(File.read(positions_file))
  
  positions_data.each do |pos_data|
    position = Position.find_or_initialize_by(name: pos_data['name'], sport: sport)
    position.assign_attributes(
      abbreviation: pos_data['abbreviation'],
      description: pos_data['description']
    )
    position.save!
    puts "Created position: #{position.name} (#{position.abbreviation}) for #{sport_name}"
  end
  
  # Assign positions to existing players
  Player.joins(team: { league: :sport }).where(sports: { name: sport_name })
        .where.not(current_position: [nil, ""]).find_each do |player|
    
    # Find matching position based on current_position field
    position_name = player.current_position
    position = sport.positions.find_by("name = ? OR abbreviation = ?", position_name, position_name)
    
    # If no exact match, try to find a partial match
    if position.nil?
      position_name_parts = position_name.split(/[\s\-\/]/).reject { |p| p.length < 2 }
      position_name_parts.each do |part|
        position = sport.positions.find_by("name LIKE ? OR abbreviation LIKE ?", "%#{part}%", "%#{part}%")
        break if position
      end
    end
    
    # If still no match, use a default position
    position ||= sport.positions.first
    
    # Create role with this position as primary
    if position
      role = player.roles.find_or_initialize_by(position: position)
      role.assign_attributes(primary: true)
      role.save!
      puts "Assigned #{position.name} to #{player.name}"
    end
  end
end

# Step 7: Create sport positions
puts "\n----- Seeding Sport Positions -----"

# Iterate through all sports and create positions
Sport.all.each do |sport|
  puts "Creating #{sport.name} positions..."
  create_sport_positions(sport.name)
end

puts "Creating Spectrums..."
spectrum_data = JSON.parse(File.read(Rails.root.join('db', 'seeds', 'athlete_ace_data', 'ratings', 'spectrums.json')))

spectrum_data.each do |attributes|
  spectrum = Spectrum.find_or_initialize_by(name: attributes['name'])
  spectrum.assign_attributes(attributes)
  spectrum.save!
  puts "  Created spectrum: #{spectrum.name}"
end

puts "Created #{Spectrum.count} spectrums"

puts "\n===== Database Seeding Complete! ====="
