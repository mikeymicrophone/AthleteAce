# AthleteAce Database Seed File
# This file loads data from the athlete_ace_data source directory

puts "===== Seeding AthleteAce Database ====="

# Step 1: Load sports data
puts "\n----- Seeding Sports -----"
sports_file = File.read(Rails.root.join('db/seeds/athlete_ace_data/sports/sports.json'))
sports = JSON.parse(sports_file)

sports.each do |sport_name|
  Sport.find_or_create_by!(name: sport_name)
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
    Country.find_or_create_by!(name: country["name"])
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
    State.find_or_create_by!(
      name: state["name"],
      abbreviation: state["abbreviation"],
      country: country
    )
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
      City.find_or_create_by!(
        name: city["name"],
        state: state
      )
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
      stadium_record = Stadium.find_or_create_by!(name: stadium["name"]) do |s|
        s.city = city
        s.capacity = stadium["capacity"] if stadium["capacity"].present?
        s.opened_year = stadium["opened_year"] if stadium["opened_year"].present?
        s.address = stadium["address"] if stadium["address"].present?
        s.url = stadium["url"] if stadium["url"].present?
      end
      
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
    League.find_or_create_by!(
      name: league["name"],
      abbreviation: league["abbreviation"],
      sport: sport,
      url: league["url"],
      year_of_origin: league["year_of_origin"],
      official_rules_url: league["official_rules_url"],
      logo_url: league["logo_url"]
    )
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
    Team.find_or_create_by!(
      mascot: team["mascot"],
      territory: team["territory"],
      abbreviation: team["abbreviation"],
      league: league,
      stadium: stadium,
      founded_year: team["founded_year"],
      url: team["url"],
      logo_url: team["logo_url"],
      primary_color: team["primary_color"],
      secondary_color: team["secondary_color"]
    )
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
    player_record = Player.find_or_create_by!(
      first_name: player["first_name"],
      last_name: player["last_name"],
      team: team
    )
    
    # Update additional player attributes if provided
    player_attrs = {}
    player_attrs[:current_position] = player["current_position"] if player["current_position"].present?
    player_attrs[:birthdate] = player["birthdate"] if player["birthdate"].present?
    player_attrs[:debut_year] = player["debut_year"] if player["debut_year"].present?
    player_attrs[:draft_year] = player["draft_year"] if player["draft_year"].present?
    player_attrs[:active] = player["active"] if player.has_key?("active")
    player_attrs[:nicknames] = player["nicknames"] if player["nicknames"].present?
    player_attrs[:bio] = player["bio"] if player["bio"].present?
    player_attrs[:photo_urls] = player["photo_urls"] if player["photo_urls"].present?
    
    player_record.update(player_attrs) if player_attrs.present?
    puts "Created/updated player: #{player['first_name']} #{player['last_name']}"
  end
end

# Step 7: Create sport positions
puts "\n----- Creating Sport Positions -----"

# Define position creation helper method
def create_sport_positions(sport_name, positions_data)
  sport = Sport.find_by(name: sport_name)
  return unless sport
  
  positions_data.each do |pos_data|
    position = Position.find_or_create_by!(name: pos_data[:name], sport: sport) do |p|
      p.abbreviation = pos_data[:abbreviation] if pos_data[:abbreviation].present?
      p.description = pos_data[:description] if pos_data[:description].present?
    end
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
      player.roles.find_or_create_by(position: position) do |role|
        role.primary = true
      end
      puts "Assigned #{position.name} to #{player.name}"
    end
  end
end

# Basketball positions
puts "Creating Basketball positions..."
basketball_positions = [
  { name: "Point Guard", abbreviation: "PG", description: "The point guard is typically the team's best ball handler and passer, responsible for organizing the team's offense and setting up scoring opportunities for teammates." },
  { name: "Shooting Guard", abbreviation: "SG", description: "The shooting guard is usually a good perimeter shooter and scorer, often serving as a secondary ball handler and perimeter defender." },
  { name: "Small Forward", abbreviation: "SF", description: "The small forward is typically a versatile player who can score from inside and outside, rebound, and defend multiple positions." },
  { name: "Power Forward", abbreviation: "PF", description: "The power forward typically plays near the basket, providing rebounding, interior defense, and scoring in the post, though modern power forwards often have perimeter skills as well." },
  { name: "Center", abbreviation: "C", description: "The center is usually the tallest player on the team, providing rebounding, shot blocking, and interior scoring." },
  { name: "Guard-Forward", abbreviation: "G-F", description: "A versatile player who can play both guard and forward positions, typically with good perimeter skills and size." },
  { name: "Forward-Center", abbreviation: "F-C", description: "A player who can play both forward and center positions, typically with good size and a mix of perimeter and post skills." },
  { name: "Forward", abbreviation: "F", description: "A general position for players who can play either small forward or power forward roles." },
  { name: "Guard", abbreviation: "G", description: "A general position for players who can play either point guard or shooting guard roles." }
]
create_sport_positions("Basketball", basketball_positions)

# Baseball positions
puts "Creating Baseball positions..."
baseball_positions = [
  { name: "Pitcher", abbreviation: "P", description: "The player who throws the ball to the batter from the pitcher's mound." },
  { name: "Catcher", abbreviation: "C", description: "Positioned behind home plate, receives pitches and calls the game." },
  { name: "First Baseman", abbreviation: "1B", description: "Defends first base and receives throws from infielders." },
  { name: "Second Baseman", abbreviation: "2B", description: "Defends second base and turns double plays." },
  { name: "Third Baseman", abbreviation: "3B", description: "Defends third base, requires quick reflexes and a strong arm." },
  { name: "Shortstop", abbreviation: "SS", description: "Positioned between second and third base, usually the most athletic infielder." },
  { name: "Left Fielder", abbreviation: "LF", description: "Defends the left portion of the outfield." },
  { name: "Center Fielder", abbreviation: "CF", description: "Covers the middle portion of the outfield, usually the fastest outfielder." },
  { name: "Right Fielder", abbreviation: "RF", description: "Defends the right portion of the outfield, typically with the strongest arm." },
  { name: "Designated Hitter", abbreviation: "DH", description: "In American League games, bats in place of the pitcher." }
]
create_sport_positions("Baseball", baseball_positions)

# Football positions
puts "Creating Football positions..."
football_positions = [
  { name: "Quarterback", abbreviation: "QB", description: "The leader of the offense who receives the snap and either passes, hands off, or runs with the ball." },
  { name: "Running Back", abbreviation: "RB", description: "Carries the ball on running plays and sometimes catches passes." },
  { name: "Wide Receiver", abbreviation: "WR", description: "Lines up on the outside and runs routes to catch passes." },
  { name: "Tight End", abbreviation: "TE", description: "A hybrid position that combines elements of an offensive lineman and a receiver." },
  { name: "Offensive Tackle", abbreviation: "OT", description: "Offensive linemen positioned on the ends of the line who protect the quarterback." },
  { name: "Offensive Guard", abbreviation: "OG", description: "Offensive linemen positioned between the center and tackles." },
  { name: "Center", abbreviation: "C", description: "The offensive lineman who snaps the ball to the quarterback." },
  { name: "Defensive End", abbreviation: "DE", description: "Defensive linemen positioned at the ends of the line who rush the passer." },
  { name: "Defensive Tackle", abbreviation: "DT", description: "Interior defensive linemen who stop running plays and pressure the quarterback." },
  { name: "Linebacker", abbreviation: "LB", description: "Second-level defenders who stop running plays, rush the passer, and cover receivers." },
  { name: "Cornerback", abbreviation: "CB", description: "Defensive backs who primarily cover wide receivers." },
  { name: "Safety", abbreviation: "S", description: "Defensive backs who line up deep in the secondary." },
  { name: "Kicker", abbreviation: "K", description: "Specialist who handles kickoffs and field goal attempts." },
  { name: "Punter", abbreviation: "P", description: "Specialist who punts the ball on fourth down." }
]
create_sport_positions("Football", football_positions)

# Hockey positions
puts "Creating Hockey positions..."
hockey_positions = [
  { name: "Center", abbreviation: "C", description: "The forward who plays in the middle of the ice, responsible for faceoffs and playmaking." },
  { name: "Left Wing", abbreviation: "LW", description: "The forward who plays on the left side of the ice." },
  { name: "Right Wing", abbreviation: "RW", description: "The forward who plays on the right side of the ice." },
  { name: "Defenseman", abbreviation: "D", description: "Players who primarily focus on preventing the opposing team from scoring." },
  { name: "Goaltender", abbreviation: "G", description: "The player responsible for directly preventing the opposing team from scoring." }
]
create_sport_positions("Hockey", hockey_positions)

# Soccer positions
puts "Creating Soccer positions..."
soccer_positions = [
  { name: "Goalkeeper", abbreviation: "GK", description: "The player who defends the team's goal, the only player allowed to use hands within their penalty area." },
  { name: "Center Back", abbreviation: "CB", description: "Central defender whose primary responsibility is to prevent the opposition from scoring." },
  { name: "Left Back", abbreviation: "LB", description: "Defender who plays on the left side of the defense." },
  { name: "Right Back", abbreviation: "RB", description: "Defender who plays on the right side of the defense." },
  { name: "Defensive Midfielder", abbreviation: "DM", description: "Midfielder who plays in front of the defense, focusing on breaking up opposition attacks." },
  { name: "Central Midfielder", abbreviation: "CM", description: "Midfielder who plays centrally, balancing defensive and offensive responsibilities." },
  { name: "Attacking Midfielder", abbreviation: "AM", description: "Midfielder who focuses primarily on creating scoring opportunities for forwards." },
  { name: "Left Midfielder", abbreviation: "LM", description: "Midfielder who plays on the left side, providing width to the team's attack." },
  { name: "Right Midfielder", abbreviation: "RM", description: "Midfielder who plays on the right side, providing width to the team's attack." },
  { name: "Striker", abbreviation: "ST", description: "Forward whose main responsibility is scoring goals." },
  { name: "Left Winger", abbreviation: "LW", description: "Attacking player who plays on the left wing, providing width to the attack." },
  { name: "Right Winger", abbreviation: "RW", description: "Attacking player who plays on the right wing, providing width to the attack." }
]
create_sport_positions("Soccer", soccer_positions)

puts "Creating Spectrums..."
require_relative 'seeds/spectrums.rb'

puts "\n===== Database Seeding Complete! ====="
