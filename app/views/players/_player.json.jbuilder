json.extract! player, :id, :first_name, :last_name, :nicknames, :birthdate, :birth_city_id, :birth_country_id, :height_ft, :height_in, :weight_lb, :jersey_number, :current_position, :debut_year, :draft_year, :active, :bio, :photo_urls, :team_id, :created_at, :updated_at
json.url player_url(player, format: :json)
