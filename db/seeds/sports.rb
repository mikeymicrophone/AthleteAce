sports_file = File.read(Rails.root.join('db/seeds/athlete_ace_data/sports/sports.json'))
sports = JSON.parse(sports_file)

sports.each do |sport_name|
  Sport.find_or_create_by!(name: sport_name)
end
