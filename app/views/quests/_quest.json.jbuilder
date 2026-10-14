json.extract! quest, :id, :name, :description, :moderation_status, :moderation_revision, :created_at, :updated_at
json.url quest_url(quest, format: :json)
