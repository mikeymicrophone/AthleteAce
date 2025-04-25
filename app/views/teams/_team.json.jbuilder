json.extract! team, :id, :mascot, :territory, :league_id, :stadium_id, :founded_year, :abbreviation, :url, :logo_url, :primary_color, :secondary_color, :created_at, :updated_at
json.url team_url(team, format: :json)
