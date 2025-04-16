# Seeds for Country, State, and City

# Example country
usa = Country.find_or_create_by!(name: "United States", abbreviation: "US")
canada = Country.find_or_create_by!(name: "Canada", abbreviation: "CA")

# Example states
california = State.find_or_create_by!(name: "California", abbreviation: "CA", country: usa)
new_york = State.find_or_create_by!(name: "New York", abbreviation: "NY", country: usa)
ontario = State.find_or_create_by!(name: "Ontario", abbreviation: "ON", country: canada)

# Example cities
City.find_or_create_by!(name: "Los Angeles", state: california)
City.find_or_create_by!(name: "San Francisco", state: california)
City.find_or_create_by!(name: "New York City", state: new_york)
City.find_or_create_by!(name: "Toronto", state: ontario)
