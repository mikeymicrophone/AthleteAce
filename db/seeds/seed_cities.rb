class SeedCities
  include SeedHelpers
  
  def self.run(glob_patterns)
    SeedHelpers.log_and_puts "\n----- Seeding Cities -----"
    
    glob_patterns[:cities].each do |pattern|
      SeedHelpers.load_json_files(pattern).each do |file_data|
        SeedHelpers.log_and_puts "Loading cities from #{SeedHelpers.relative_path(file_data[:path])}"
        
        country = Country.find_by(name: file_data[:data]['country_name'])
        if country.nil?
          SeedHelpers.log_and_puts "Warning: Country not found: #{file_data[:data]['country_name']}"
          next
        end
        
        file_data[:data]['cities'].each do |city_data|
          # Find state by abbreviation
          state = State.find_by(abbreviation: city_data['state'], country: country)
          
          if state.nil?
            SeedHelpers.log_and_puts "Warning: State not found: #{city_data['state']} in #{country.name}"
            next
          end
          
          attributes = city_data.except('state').merge('state' => state)
          
          SeedHelpers.find_or_create_with_changes(
            City,
            { name: city_data['name'], state: state },
            attributes.except('name')
          )
        end
      end
    end
    
    SeedHelpers.log_and_puts "Cities seeding complete: #{City.count} total"
  end
end