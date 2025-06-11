class SeedStates
  include SeedHelpers
  
  def self.run(glob_patterns)
    SeedHelpers.log_and_puts "\n----- Seeding States -----"
    
    glob_patterns[:states].each do |pattern|
      SeedHelpers.load_json_files(pattern).each do |file_data|
        SeedHelpers.log_and_puts "Loading states from #{SeedHelpers.relative_path(file_data[:path])}"
        
        country = Country.find_by(name: file_data[:data]['country_name'])
        if country.nil?
          SeedHelpers.log_and_puts "Warning: Country not found: #{file_data[:data]['country_name']}"
          next
        end
        
        file_data[:data]['states'].each do |state_data|
          attributes = state_data.merge('country' => country)
          
          SeedHelpers.find_or_create_with_changes(
            State,
            { name: state_data['name'], abbreviation: state_data['abbreviation'] },
            attributes.except('name', 'abbreviation')
          )
        end
      end
    end
    
    SeedHelpers.log_and_puts "States seeding complete: #{State.count} total"
  end
end