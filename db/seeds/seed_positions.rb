class SeedPositions
  include SeedHelpers
  
  def self.run(glob_patterns)
    SeedHelpers.log_and_puts "\n----- Seeding Positions -----"
    
    glob_patterns[:positions].each do |pattern|
      SeedHelpers.load_json_files(pattern).each do |file_data|
        SeedHelpers.log_and_puts "Loading positions from #{SeedHelpers.relative_path(file_data[:path])}"
        
        # Extract sport name from file path (e.g., "baseball.json" -> "baseball")
        sport_name = File.basename(file_data[:path], '.json').capitalize
        sport = Sport.find_by(name: sport_name)
        
        if sport.nil?
          SeedHelpers.log_and_puts "Warning: Sport not found: #{sport_name}"
          next
        end
        
        # Handle both array format and object format
        positions_data = file_data[:data].is_a?(Array) ? file_data[:data] : file_data[:data]['positions']
        
        positions_data.each do |position_data|
          attributes = position_data.merge('sport' => sport)
          
          SeedHelpers.find_or_create_with_changes(
            Position,
            { name: position_data['name'], sport: sport },
            attributes.except('name')
          )
        end
      end
    end
    
    # Assign positions to existing players
    assign_positions_to_players
    
    SeedHelpers.log_and_puts "Positions seeding complete: #{Position.count} total"
  end
  
  private
  
  def self.assign_positions_to_players
    SeedHelpers.log_and_puts "Assigning positions to existing players..."
    
    Sport.includes(:positions).each do |sport|
      next if sport.positions.empty?
      
      Player.joins(team: { league: :sport })
            .where(sports: { name: sport.name })
            .where.not(current_position: [nil, ""])
            .find_each do |player|
        
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
          if role.new_record? || !role.primary?
            role.assign_attributes(primary: true)
            role.save!
            SeedHelpers.log_and_puts "Assigned #{position.name} to #{player.first_name} #{player.last_name}"
          end
        end
      end
    end
  end
end