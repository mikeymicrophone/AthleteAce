class SeedStadiums
  include SeedHelpers
  
  def self.run(glob_patterns)
    SeedHelpers.log_and_puts "\n----- Seeding Stadiums -----"
    
    glob_patterns.each do |pattern|
      SeedHelpers.load_json_files(pattern).each do |file_data|
        SeedHelpers.log_and_puts "Loading stadiums from #{SeedHelpers.relative_path(file_data[:path])}"
        
        country = Country.find_by(name: file_data[:data]['country_name'])
        if country.nil?
          SeedHelpers.log_and_puts "Warning: Country not found: #{file_data[:data]['country_name']}"
          next
        end
        
        file_data[:data]['stadiums'].each do |stadium_data|
          # Find the state by name (using LIKE for partial matches)
          state_name = stadium_data['state_name']
          state = State.find_by("name LIKE ?", "%#{state_name}%")
          
          # Find the city by name and state
          city = nil
          if state
            city = City.find_by(name: stadium_data['city_name'], state: state)
          end
          
          # If city not found, try to find by name only
          if city.nil?
            city = City.find_by(name: stadium_data['city_name'])
          end
          
          if city.nil?
            SeedHelpers.log_and_puts "Warning: City not found: #{stadium_data['city_name']} in #{stadium_data['state_name']}"
            next
          end
          
          attributes = stadium_data.except('state_name', 'city_name').merge('city' => city)
          # Ensure logo_url has a default value
          attributes['logo_url'] ||= ""
          
          SeedHelpers.find_or_create_with_changes(
            Stadium,
            { name: stadium_data['name'] },
            attributes.except('name')
          )
        end
      end
    end
    
    SeedHelpers.log_and_puts "Stadiums seeding complete: #{Stadium.count} total"
  end
end