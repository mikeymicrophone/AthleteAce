class SeedContracts
  include SeedHelpers
  
  def self.run(glob_patterns)
    SeedHelpers.log_and_puts "\n----- Seeding Contracts -----"
    
    glob_patterns.each do |pattern|
      SeedHelpers.load_json_files(pattern).each do |file_data|
        SeedHelpers.log_and_puts "Loading contracts from #{SeedHelpers.relative_path(file_data[:path])}"
        
        # Determine sport from file path
        sport = determine_sport_from_path(file_data[:path])
        unless sport
          SeedHelpers.log_and_puts "Warning: Could not determine sport from path: #{file_data[:path]}"
          next
        end
        
        # Extract team name from JSON data
        team_name = file_data[:data]['team_name']
        unless team_name
          SeedHelpers.log_and_puts "Warning: No team_name found in JSON: #{file_data[:path]}"
          next
        end
        
        team = find_team_by_sport_and_mascot(sport, team_name)
        if team.nil?
          SeedHelpers.log_and_puts "Warning: Team not found: #{team_name} in #{sport.name}"
          next
        end
        
        contract_group = file_data[:data]['contract_group'] || File.basename(file_data[:path], '.json')
        SeedHelpers.log_and_puts "  Processing #{contract_group} for #{team.name}"
        
        file_data[:data]['contracts'].each do |contract_data|
          create_contract(contract_data, team, sport)
        end
      end
    end
  end
  
  private
  
  def self.determine_sport_from_path(path)
    # Extract sport name from path structure: db/seeds/athlete_ace_data/sports/[sport]/...
    path_parts = path.split('/')
    sports_index = path_parts.index('sports')
    return nil unless sports_index && path_parts[sports_index + 1]
    
    sport_name = path_parts[sports_index + 1]
    Sport.find_by(name: sport_name.capitalize)
  end
  
  def self.find_team_by_sport_and_mascot(sport, mascot)
    Team.joins(league: :sport)
        .where(sports: { id: sport.id })
        .find_by(mascot: mascot.titleize)
  end
  
  def self.create_contract(contract_data, team, sport)
    # Find player by name within the sport
    player = find_player_by_name_and_sport(contract_data['player_name'], sport)
    unless player
      SeedHelpers.log_and_puts "Warning: Player not found: #{contract_data['player_name']} in #{sport.name}"
      return
    end
    
    # Parse dates
    start_date = contract_data['start_date'] ? Date.parse(contract_data['start_date']) : nil
    end_date = contract_data['end_date'] ? Date.parse(contract_data['end_date']) : nil
    
    # Create or update contract
    contract = Contract.find_or_initialize_by(
      player: player,
      team: team,
      start_date: start_date
    )
    
    contract.assign_attributes(
      end_date: end_date,
      total_dollar_value: contract_data['total_dollar_value'],
      details: contract_data['details'],
      seed_version: SeedVersion.seed_version,
      last_seeded_at: SeedVersion.last_seeded_at
    )
    
    if contract.save
      SeedHelpers.log_and_puts "  ✓ Contract: #{player.name} with #{team.name} (#{start_date || 'No start'} - #{end_date || 'No end'})"
    else
      SeedHelpers.log_and_puts "  ✗ Failed to save contract for #{player.name}: #{contract.errors.full_messages.join(', ')}"
    end
    
    contract
  end
  
  def self.find_player_by_name_and_sport(player_name, sport)
    # Split name into first and last
    name_parts = player_name.split(' ')
    return nil if name_parts.length < 2
    
    first_name = name_parts.first
    last_name = name_parts[1..-1].join(' ')
    
    Player.joins(team: { league: :sport })
          .where(sports: { id: sport.id })
          .find_by(first_name: first_name, last_name: last_name)
  end
end