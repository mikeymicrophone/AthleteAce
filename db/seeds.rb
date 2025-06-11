# AthleteAce Database Seed File
# This file orchestrates the seeding process using modular seed files

# Load seed helpers and individual seed classes
require_relative '../lib/seed_helpers'
Dir[Rails.root.join('db/seeds/seed_*.rb')].each { |file| require file }

# Configure seed versioning
class SeedVersion < ActiveSupport::CurrentAttributes
  attribute :seed_version, :string
  attribute :last_seeded_at, :datetime
  attribute :seeded_models, :array, default: []
end

SeedVersion.seeded_models = [Country, State, City, Stadium, Sport, League, Conference, Division, Team, Player, Membership, Position, Role, Spectrum, Quest, Achievement, Highlight, Year, Season]

ApplicationRecord.before_create do
  self.seed_version ||= SeedVersion.seed_version
  self.last_seeded_at ||= SeedVersion.last_seeded_at
end

# Initialize seeding
SeedHelpers.init_logging
SeedHelpers.log_and_puts "===== Seeding AthleteAce Database ====="

# Calculate seed version
previous_seed_version = SeedVersion.seeded_models.map { |model| model.seeded.last&.seed_version =~ /^(\d+)\.\d+\.\d+\.\d+$/ ; $1.to_i }.max || 0
SeedHelpers.log_and_puts "Previous seed version: #{previous_seed_version}"
SeedVersion.seed_version = "%03d.#{Time.current.strftime('%Y.%m.%d')}" % (previous_seed_version + 1)
SeedVersion.last_seeded_at = Time.current

# Define glob patterns for each resource type
glob_patterns = {
  sports: ['sports/sports.json'],
  countries: ['locations/countries/*.json'],
  federations: ['locations/federations/federations.json'],
  states: ['locations/states/*.json'],
  cities: ['locations/cities/*.json'],
  stadiums: ['locations/stadiums/*.json'],
  leagues: ['sports/**/leagues.json'],
  conferences: ['sports/**/conferences.json'],
  teams: ['sports/**/teams.json'],
  players: ['sports/**/players/*.json'],
  memberships: ['sports/**/memberships.json'],
  positions: ['sports/positions/*.json'],
  spectrums: ['ratings/spectrums.json'],
  quests: ['quests/*.json'],
  achievements: ['achievements/*.json'],
  seasons: ['sports/**/seasons.json']
}

# Clean up legacy files
SeedHelpers.cleanup_legacy_files

# Run seed steps in dependency order
begin
  SeedSports.run(glob_patterns[:sports])
  SeedCountries.run(glob_patterns[:countries])
  SeedFederations.run(glob_patterns[:federations])
  SeedStates.run(glob_patterns[:states])
  SeedCities.run(glob_patterns[:cities])
  SeedStadiums.run(glob_patterns[:stadiums])
  SeedLeagues.run(glob_patterns[:leagues])
  SeedConferences.run(glob_patterns[:conferences])
  SeedTeams.run(glob_patterns[:teams])
  SeedPlayers.run(glob_patterns[:players])
  SeedMemberships.run(glob_patterns[:memberships])
  SeedPositions.run(glob_patterns[:positions])
  SeedSpectrums.run(glob_patterns[:spectrums])
  SeedQuests.run(glob_patterns[:quests])
  SeedYears.run(glob_patterns[:years] || [])
  SeedSeasons.run(glob_patterns[:seasons])
  SeedCampaigns.run([])  # Generate from existing data, no JSON files needed
  
  SeedHelpers.log_and_puts "\n===== Database Seeding Complete! ====="
rescue => e
  SeedHelpers.log_and_puts "ERROR: Seeding failed with: #{e.message}"
  SeedHelpers.log_and_puts e.backtrace.join("\n")
  raise e
end
