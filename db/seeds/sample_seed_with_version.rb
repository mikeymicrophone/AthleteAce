# Sample seed file demonstrating the with_seed_version method
# Run with: rails runner db/seeds/sample_seed_with_version.rb

# Using a numbered format with date for better sorting (increment.year.month.day)
SEED_VERSION = "001.2025.05.23"

# All database operations inside this block will automatically include 
# seed_version and last_seeded_at without manual assignment
ApplicationRecord.with_seed_version SEED_VERSION do
  # Create operations get seed attributes automatically
  sport = Sport.find_or_create_by name: "Basketball"
  
  # Updates also get seed attributes
  league = League.find_or_initialize_by name: "NBA"
  league.sport = sport
  league.save
  
  # Bulk operations also work
  eastern = Conference.find_or_create_by name: "Eastern"
  western = Conference.find_or_create_by name: "Western"
  
  # Even when using associations
  eastern.divisions.find_or_create_by name: "Atlantic"
  eastern.divisions.find_or_create_by name: "Central"
  eastern.divisions.find_or_create_by name: "Southeast"
  
  western.divisions.find_or_create_by name: "Northwest"
  western.divisions.find_or_create_by name: "Pacific"
  western.divisions.find_or_create_by name: "Southwest"
end

# Verify some of the records have seed information
puts "Seed verification:"
Sport.last(3).each do |sport|
  puts "#{sport.name}: seed_version=#{sport.seed_version}, last_seeded_at=#{sport.last_seeded_at}"
end
