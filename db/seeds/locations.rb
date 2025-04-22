# Seeds for Country, State, and City
country_file = File.read(Rails.root.join('db/seeds/athlete_ace_data/locations/countries/countries.json'))
countries = JSON.parse(country_file)

countries.each do |country|
  Country.find_or_create_by!(name: country["name"], abbreviation: country["abbreviation"])
end

Dir.glob('db/seeds/athlete_ace_data/locations/states/*.json').each do |file|
  state_file = File.read(Rails.root.join(file))
  state_data = JSON.parse(state_file)
  country_name = state_data["country_name"]
  states = state_data["states"]

  states.each do |state|
    State.find_or_create_by!(name: state["name"], abbreviation: state["abbreviation"], country: Country.find_by(name: country_name))
  end
end

Dir.glob('db/seeds/athlete_ace_data/locations/cities/*.json').each do |file|
  city_file = File.read(Rails.root.join(file))
  city_data = JSON.parse(city_file)
  country_name = city_data["country_name"]
  country = Country.find_by(name: country_name)
  cities = city_data["cities"]

  cities.each do |city|
    puts city
    City.find_or_create_by!(name: city["name"], state: country.states.find_by(abbreviation: city["state"]))
  end
end
