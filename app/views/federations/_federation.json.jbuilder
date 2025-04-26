json.extract! federation, :id, :name, :abbreviation, :description, :url, :logo_url, :created_at, :updated_at
json.url federation_url(federation, format: :json)
