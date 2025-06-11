class SeedLeagues
  include SeedHelpers
  
  def self.run(glob_patterns)
    SeedHelpers.log_and_puts "\n----- Seeding Leagues -----"
    
    glob_patterns.each do |pattern|
      SeedHelpers.load_json_files(pattern).each do |file_data|
        SeedHelpers.log_and_puts "Loading leagues from #{SeedHelpers.relative_path(file_data[:path])}"
        
        sport = Sport.find_by(name: file_data[:data]['sport_name'])
        if sport.nil?
          SeedHelpers.log_and_puts "Warning: Sport not found: #{file_data[:data]['sport_name']}"
          next
        end
        
        # Determine jurisdiction (Federation or Country)
        jurisdiction = nil
        if file_data[:data]['federation_name']
          jurisdiction = Federation.find_by(abbreviation: file_data[:data]['federation_name'])
          if jurisdiction.nil?
            SeedHelpers.log_and_puts "Warning: Federation not found: #{file_data[:data]['federation_name']}"
            next
          end
        elsif file_data[:data]['country_name']
          jurisdiction = Country.find_by(name: file_data[:data]['country_name'])
          if jurisdiction.nil?
            SeedHelpers.log_and_puts "Warning: Country not found: #{file_data[:data]['country_name']}"
            next
          end
        end
        
        file_data[:data]['leagues'].each do |league_data|
          attributes = league_data.merge(
            'sport' => sport,
            'jurisdiction' => jurisdiction
          )
          
          SeedHelpers.find_or_create_with_changes(
            League,
            { name: league_data['name'] },
            attributes.except('name')
          )
        end
      end
    end
    
    SeedHelpers.log_and_puts "Leagues seeding complete: #{League.count} total"
  end
end