# Routes for the players resource
Rails.application.routes.draw do
  # Use the filterable_resources method to create nested routes for all filterable associations
  filterable_resources :players do
    resources :ratings, only: [:new, :create]
    get 'strength/game_attempts', to: 'strength#player_game_attempts'
  end
end
