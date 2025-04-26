Dir.glob(Rails.root.join('db/seeds/athlete_ace_data/sports/**/leagues.json')).each do |file|
  league_file = File.read(file)
  league_json = JSON.parse(league_file)
  sport = Sport.find_by(name: league_json['sport_name'])
  country = Country.find_by(name: league_json['country_name'])
  jurisdiction = country
  leagues = league_json['leagues']
  leagues.each do |league|
    League.find_or_create_by!(
      name: league["name"],
      abbreviation: league["abbreviation"],
      sport: sport,
      jurisdiction: jurisdiction,
      url: league["url"],
      ios_app_url: league["ios_app_url"],
      year_of_origin: league["year_of_origin"],
      official_rules_url: league["official_rules_url"],
      logo_url: league["logo_url"]
    )
  end
end
