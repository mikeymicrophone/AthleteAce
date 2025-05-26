# Define which models can be rated through the app
Rails.application.config.ratable_models = [
  'Player',
  'Team',
  'Division'
]

# Create a hash version for faster lookups
Rails.application.config.ratable_models_hash = Rails.application.config.ratable_models.index_by(&:itself)
