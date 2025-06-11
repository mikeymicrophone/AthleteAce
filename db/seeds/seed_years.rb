class SeedYears
  include SeedHelpers
  
  def self.run(glob_patterns = {})
    SeedHelpers.log_and_puts "\n----- Seeding Years -----"
    SeedHelpers.log_and_puts "Creating Years from 1800 to #{Date.current.year}..."
    
    (1800..Date.current.year).each do |year_number|
      SeedHelpers.find_or_create_with_changes(
        Year,
        { number: year_number }
      )
    end
    
    SeedHelpers.log_and_puts "Years seeding complete: #{Year.count} total"
  end
end