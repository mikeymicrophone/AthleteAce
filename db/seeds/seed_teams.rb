class SeedTeams
  include SeedHelpers
  
  def self.run(glob_patterns)
    SeedHelpers.log_and_puts "\n----- Seeding Teams -----"
    
    glob_patterns.each do |pattern|
      SeedHelpers.load_json_files(pattern).each do |file_data|
        SeedHelpers.log_and_puts "Loading teams from #{SeedHelpers.relative_path(file_data[:path])}"
        
        league = League.find_by(name: file_data[:data]['league_name'])
        if league.nil?
          SeedHelpers.log_and_puts "Warning: League not found: #{file_data[:data]['league_name']}"
          next
        end
        
        file_data[:data]['teams'].each do |team_data|
          # Find the stadium if specified
          stadium = nil
          if team_data['stadium_name']
            stadium = Stadium.find_by(name: team_data['stadium_name'])
            if stadium.nil?
              SeedHelpers.log_and_puts "Warning: Stadium not found: #{team_data['stadium_name']}"
            end
          end
          
          attributes = team_data.except('stadium_name').merge('league_id' => league.id)
          attributes['stadium_id'] = stadium.id if stadium
          
          # Use territory and mascot for uniqueness since that's how teams are typically identified
          find_attributes = if team_data['territory']
            { territory: team_data['territory'], mascot: team_data['mascot'] }
          else
            { mascot: team_data['mascot'] }
          end
          
          SeedHelpers.find_or_create_with_changes(
            Team,
            find_attributes,
            attributes.except('territory', 'mascot')
          )
        end
      end
    end
    
    SeedHelpers.log_and_puts "Teams seeding complete: #{Team.count} total"
  end
end