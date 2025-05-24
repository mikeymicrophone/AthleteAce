# Sample seed file demonstrating the with_seed_version method
# Run with: rails runner db/seeds/sample_seed_with_version.rb

# Using a numbered format with date for better sorting (increment.year.month.day)
SEED_VERSION = "001.2025.05.23"

# All database operations inside this block will automatically include 
# seed_version and last_seeded_at without manual assignment
SeedHelper.with_seed_version SEED_VERSION do
  # ========== Create Operations ==========
  # These operations automatically get seed_version and last_seeded_at
  
  # Simple create operations
  basketball = Sport.find_or_create_by name: "Basketball"
  baseball = Sport.find_or_create_by name: "Baseball"
  
  # Create with associations
  nba = League.find_or_create_by name: "NBA", sport: basketball
  mlb = League.find_or_create_by name: "MLB", sport: baseball
  
  # Create through associations
  eastern = Conference.find_or_create_by name: "Eastern", league: nba
  western = Conference.find_or_create_by name: "Western", league: nba
  
  # Nested creation
  eastern.divisions.find_or_create_by name: "Atlantic"
  eastern.divisions.find_or_create_by name: "Central"
  eastern.divisions.find_or_create_by name: "Southeast"
  
  western.divisions.find_or_create_by name: "Northwest"
  western.divisions.find_or_create_by name: "Pacific"
  western.divisions.find_or_create_by name: "Southwest"
  
  # ========== Update Operations ==========
  # Updates also get seed_version and last_seeded_at
  
  # Update existing records
  bulls = Team.find_or_initialize_by name: "Chicago Bulls"
  bulls.city = "Chicago"
  bulls.save
  
  # Multiple ways to update
  lakers = Team.find_or_initialize_by name: "Los Angeles Lakers"
  lakers.update city: "Los Angeles"
  
  # Update with associations
  celtics = Team.find_or_initialize_by name: "Boston Celtics"
  celtics.city = "Boston"
  celtics.division = eastern.divisions.find_by(name: "Atlantic")
  celtics.save
end

# ========== Verification ==========
# Verify that the records have seed information
puts "Seed verification:"

puts "\nSports:"
Sport.last(2).each do |sport|
  puts "  #{sport.name}: seed_version=#{sport.seed_version}, last_seeded_at=#{sport.last_seeded_at}"
end

puts "\nTeams:"
Team.all.each do |team|
  puts "  #{team.name}: seed_version=#{team.seed_version}, last_seeded_at=#{team.last_seeded_at}"
end
