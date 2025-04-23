# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Main seeds file
# Loads sub-seed files for modular seeding

# Seed sports (keep here as a base dependency)
load Rails.root.join('db/seeds/sports.rb')

# Seed locations (countries, states, cities)
load Rails.root.join('db/seeds/locations.rb')

# Seed leagues and stadia
load Rails.root.join('db/seeds/leagues.rb')

# Seed stadia
load Rails.root.join('db/seeds/stadiums.rb')

# Teams seeds should go in db/seeds/teams/
load Rails.root.join('db/seeds/teams.rb')

# Players seeds should go in db/seeds/players/
Dir.glob(Rails.root.join('db/seeds/players/**/*.rb')).each do |file|
  load file
end

