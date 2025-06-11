class SeedFederations
  include SeedHelpers
  
  def self.run(glob_patterns)
    SeedHelpers.log_and_puts "\n----- Seeding Federations -----"
    
    glob_patterns[:federations].each do |pattern|
      SeedHelpers.load_json_files(pattern).each do |file_data|
        SeedHelpers.log_and_puts "Loading federations from #{SeedHelpers.relative_path(file_data[:path])}"
        
        # Handle both array format and nested object format
        federations_data = if file_data[:data]['federations']
          file_data[:data]['federations']
        elsif file_data[:data].is_a?(Array)
          file_data[:data]
        else
          [file_data[:data]]
        end
        
        federations_data.each do |federation_data|
          SeedHelpers.find_or_create_with_changes(
            Federation,
            { name: federation_data['name'] },
            federation_data.except('name')
          )
        end
      end
    end
    
    SeedHelpers.log_and_puts "Federations seeding complete: #{Federation.count} total"
  end
end