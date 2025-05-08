json.extract! division, :id, :name, :abbreviation, :logo_url, :conference_id, :created_at, :updated_at
json.url division_url(division, format: :json)
json.conference do
  json.name division.conference.name
  json.id division.conference.id
end
json.league do
  json.name division.conference.league.name
  json.id division.conference.league.id
end
json.teams_count division.teams.count
