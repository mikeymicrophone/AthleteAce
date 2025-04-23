Dir.glob("db/seeds/athlete_ace_data/locations/stadiums/*.json").each do |file|
  stadiums_data = JSON.parse(File.read(file))
  country = Country.find_by!(name: stadiums_data["country_name"])
  stadiums_data["stadiums"].each do |stadium|
    state = State.find_by!(name: stadium["state_name"], country: country)
    city = City.find_by!(name: stadium["city_name"], state: state)
    Stadium.find_or_create_by!(
      name: stadium["name"],
      city: city,
      capacity: stadium["capacity"],
      opened_year: stadium["opened_year"],
      address: stadium["address"]
    )
  end
end
