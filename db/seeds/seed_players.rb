class SeedPlayers
  include SeedHelpers
  
  def self.run(glob_patterns)
    SeedHelpers.log_and_puts "\n----- Seeding Players -----"
    
    glob_patterns[:players].each do |pattern|
      SeedHelpers.load_json_files(pattern).each do |file_data|
        SeedHelpers.log_and_puts "Loading players from #{SeedHelpers.relative_path(file_data[:path])}"
        
        # Handle both single-file and per-team formats
        if file_data[:data]['league_name']
          # Single file format with all players
          league = League.find_by(name: file_data[:data]['league_name'])
          if league.nil?
            SeedHelpers.log_and_puts "Warning: League not found: #{file_data[:data]['league_name']}"
            next
          end
          
          file_data[:data]['players'].each do |player_data|
            team = Team.find_by(mascot: player_data['team_name'])
            if team.nil?
              SeedHelpers.log_and_puts "Warning: Team not found: #{player_data['team_name']}"
              next
            end
            
            create_player(player_data, team)
          end
        else
          # Per-team format
          team_name = file_data[:data]['team_name']
          team = Team.find_by(mascot: team_name)
          
          if team.nil?
            SeedHelpers.log_and_puts "Warning: Team not found: #{team_name}"
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