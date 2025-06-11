class SeedCountries
  include SeedHelpers
  
  def self.run(glob_patterns)
    SeedHelpers.log_and_puts "\n----- Seeding Countries -----"
    
    glob_patterns.each do |pattern|
      SeedHelpers.load_json_files(pattern).each do |file_data|
        SeedHelpers.log_and_puts "Loading countries from #{SeedHelpers.relative_path(file_data[:path])}"
        
        # Handle both array format and object format
        countries_data = file_data[:data].is_a?(Array) ? file_data[:data] : file_data[:data]['countries']
        
        countries_data.each do |country_data|
          SeedHelpers.find_or_create_with_changes(
            Country,
            { name: country_data['name'] },
            country_data.except('name')
          )
        end
      end
    end
    
    SeedHelpers.log_and_puts "Countries seeding complete: #{Country.count} total"
  end
end