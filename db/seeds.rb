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
["Baseball", "Basketball", "Football", "Soccer", "Hockey", "Lacrosse", "Rugby", "Cricket"].each do |sport_name|
  Sport.find_or_create_by!(name: sport_name)
end

# Seed locations (countries, states, cities)
load Rails.root.join('db/seeds/locations.rb')

# Seed leagues and stadia
load Rails.root.join('db/seeds/leagues_and_stadia.rb')

# Teams seeds should go in db/seeds/teams/
# Players seeds should go in db/seeds/players/
