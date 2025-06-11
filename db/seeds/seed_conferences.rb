class SeedConferences
  include SeedHelpers
  
  def self.run(glob_patterns)
    SeedHelpers.log_and_puts "\n----- Seeding Conferences and Divisions -----"
    
    glob_patterns.each do |pattern|
      SeedHelpers.load_json_files(pattern).each do |file_data|
        SeedHelpers.log_and_puts "Loading conferences from #{SeedHelpers.relative_path(file_data[:path])}"
        
        league = League.find_by(name: file_data[:data]['league_name'])
        if league.nil?
          SeedHelpers.log_and_puts "Warning: League not found: #{file_data[:data]['league_name']}"
          next
        end
        
        file_data[:data]['conferences'].each do |conference_data|
          attributes = conference_data.except('divisions').merge('league' => league)
          
          conference = SeedHelpers.find_or_create_with_changes(
            Conference,
            { name: conference_data['name'], league: league },
            attributes.except('name')
          )
          
          # Handle divisions if they exist
          if conference_data['divisions']
            conference_data['divisions'].each do |division_data|
              division_attributes = division_data.merge('conference' => conference)
              
              SeedHelpers.find_or_create_with_changes(
                Division,
                { name: division_data['name'], conference: conference },
                division_attributes.except('name')
              )
            end
          end
        end
      end
    end
    
    SeedHelpers.log_and_puts "Conferences and Divisions seeding complete: #{Conference.count} conferences, #{Division.count} divisions"
  end
end