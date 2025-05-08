json.extract! conference, :id, :name, :abbreviation, :logo_url, :league_id, :created_at, :updated_at
json.url conference_url(conference, format: :json)
json.league do
  json.name conference.league.name
  json.id conference.league.id
end
json.divisions_count conference.divisions.count
json.teams_count conference.teams.count
