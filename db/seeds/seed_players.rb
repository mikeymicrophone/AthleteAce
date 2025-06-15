class SeedPlayers
  include SeedHelpers
  
  def self.run(glob_patterns)
    SeedHelpers.log_and_puts "\n----- Seeding Players -----"
    
    glob_patterns.each do |pattern|
      SeedHelpers.load_json_files(pattern).each do |file_data|
        SeedHelpers.log_and_puts "Loading players from #{SeedHelpers.relative_path(file_data[:path])}"
        
        # Determine sport from file path
        sport = determine_sport_from_path(file_data[:path])
        unless sport
          SeedHelpers.log_and_puts "Warning: Could not determine sport from path: #{file_data[:path]}"
          next
        end
        
        # Handle different formats
        if file_data[:data]['league_name']
          # Single file format with all players and specified league
          league = League.joins(:sport).find_by(name: file_data[:data]['league_name'], sports: { name: sport.name })
          if league.nil?
            SeedHelpers.log_and_puts "Warning: League not found: #{file_data[:data]['league_name']} for sport #{sport.name}"
            next
          end
          
          file_data[:data]['players'].each do |player_data|
            team = find_team_by_sport_and_mascot(sport, player_data['team_name'])
            if team.nil?
              SeedHelpers.log_and_puts "Warning: Team not found: #{player_data['team_name']} in #{sport.name}"
              next
            end
            
            create_player(player_data, team)
          end
        else
          # Per-team format (including multi-team format)
          team_name = file_data[:data]['team_name']
          team = find_team_by_sport_and_mascot(sport, team_name)
          
          if team.nil?
            SeedHelpers.log_and_puts "Warning: Team not found: #{team_name} in #{sport.name}"
            next
          end
          
          file_data[:data]['players'].each do |player_data|
            create_player(player_data, team)
          end
        end
      end
    end
    
    SeedHelpers.log_and_puts "Players seeding complete: #{Player.count} total"
  end
  
  private
  
  # Determine sport from file path
  def self.determine_sport_from_path(file_path)
    path_parts = file_path.split('/')
    sport_index = path_parts.find_index('sports')
    return nil unless sport_index && sport_index + 1 < path_parts.length
    
    sport_name = path_parts[sport_index + 1].capitalize
    Sport.find_by(name: sport_name)
  end
  
  # Find team by sport and mascot, handling conflicts
  def self.find_team_by_sport_and_mascot(sport, mascot)
    Team.joins(league: :sport).find_by(
      mascot: mascot,
      sports: { name: sport.name }
    )
  end
  
  def self.create_player(player_data, team)
    # Parse birthdate if it exists
    attributes = player_data.dup
    if attributes['birthdate']
      begin
        attributes['birthdate'] = Date.parse(attributes['birthdate'])
      rescue Date::Error
        attributes['birthdate'] = nil
      end
    end
    
    # Add team association
    attributes['team'] = team
    
    SeedHelpers.find_or_create_with_changes(
      Player,
      { 
        first_name: player_data['first_name'], 
        last_name: player_data['last_name'],
        team: team
      },
      attributes.except('first_name', 'last_name', 'team_name')
    )
  end
end