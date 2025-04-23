Dir.glob(Rails.root.join('db/seeds/athlete_ace_data/sports/**/teams.json')).each do |file|
    teams_file = File.read(file)
    puts teams_file
    teams = JSON.parse(teams_file)
    league = League.find_by(name: teams["league_name"])
    teams["teams"].each do |team|
        stadium = Stadium.find_by(name: team["stadium_name"])
        Team.find_or_create_by!(
            mascot: team["mascot"],
            territory: team["territory"],
            abbreviation: team["abbreviation"],
            league: league,
            stadium: stadium,
            founded_year: team["founded_year"],
            url: team["url"],
            logo_url: team["logo_url"],
            primary_color: team["primary_color"],
            secondary_color: team["secondary_color"]
        )
    end
end
