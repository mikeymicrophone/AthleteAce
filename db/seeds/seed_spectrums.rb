class SeedSpectrums
  include SeedHelpers
  
  def self.run(glob_patterns)
    SeedHelpers.log_and_puts "\n----- Seeding Spectrums -----"
    
    glob_patterns.each do |pattern|
      SeedHelpers.load_json_files(pattern).each do |file_data|
        SeedHelpers.log_and_puts "Loading spectrums from #{SeedHelpers.relative_path(file_data[:path])}"
        
        # Handle both array format and object format
        spectrums_data = file_data[:data].is_a?(Array) ? file_data[:data] : file_data[:data]['spectrums']
        
        spectrums_data.each do |spectrum_data|
          SeedHelpers.find_or_create_with_changes(
            Spectrum,
            { name: spectrum_data['name'] },
            spectrum_data.except('name')
          )
        end
      end
    end
    
    SeedHelpers.log_and_puts "Spectrums seeding complete: #{Spectrum.count} total"
  end
end