class SeedSeasons
  include SeedHelpers
  
  def self.run(glob_patterns)
    SeedHelpers.log_and_puts "\n----- Seeding Seasons -----"
    
    glob_patterns.each do |pattern|
      SeedHelpers.load_json_files(pattern).each do |file_data|
        SeedHelpers.log_and_puts "Loading seasons from #{SeedHelpers.relative_path(file_data[:path])}"
        
        league = League.find_by(name: file_data[:data]['league_name'])
        if league.nil?
          SeedHelpers.log_and_puts "Warning: League not found: #{file_data[:data]['league_name']}"
          next
        end
        
        file_data[:data]['seasons'].each do |season_data|
          year = Year.find_by(number: season_data['year'])
          if year.nil?
            SeedHelpers.log_and_puts "Warning: Year not found: #{season_data['year']}"
            next
          end
          
          # Parse date fields
          attributes = season_data.except('year').dup
          %w[start_date end_date playoff_start_date playoff_end_date].each do |date_field|
            if attributes[date_field]
              attributes[date_field] = Date.parse(attributes[date_field])
            end
          end
          
          # Ensure comments is an array
          attributes['comments'] ||= []
          
          SeedHelpers.find_or_create_with_changes(
            Season,
            { year: year, league: league },
            attributes
          )
        end
      end
    end
    
    SeedHelpers.log_and_puts "Seasons seeding complete: #{Season.count} total"
  end
end