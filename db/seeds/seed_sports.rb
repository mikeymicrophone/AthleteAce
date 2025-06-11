class SeedSports
  include SeedHelpers
  
  def self.run(glob_patterns)
    SeedHelpers.log_and_puts "\n----- Seeding Sports -----"
    
    glob_patterns.each do |pattern|
      SeedHelpers.load_json_files(pattern).each do |file_data|
        SeedHelpers.log_and_puts "Loading sports from #{SeedHelpers.relative_path(file_data[:path])}"
        
        # Handle both array format and object format
        sports_data = file_data[:data].is_a?(Array) ? file_data[:data] : file_data[:data]['sports']
        
        sports_data.each do |sport_data|
          SeedHelpers.find_or_create_with_changes(
            Sport,
            { name: sport_data['name'] },
            sport_data.except('name')
          )
        end
      end
    end
    
    SeedHelpers.log_and_puts "Sports seeding complete: #{Sport.count} total"
  end
end