Dir.glob(Rails.root.join('db/seeds/athlete_ace_data/sports/**/players/*.json')).each do |file|
    players_file = File.read(file)
    players = JSON.parse(players_file)
    team = Team.find_by(mascot: players["team_name"])
    players["players"].each do |player|
        Player.find_or_create_by!(
            first_name: player["first_name"],
            last_name: player["last_name"],
            team: team
        )
    end
end
