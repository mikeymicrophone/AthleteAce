# Routes for the teams resource
Rails.application.routes.draw do
  # Use the filterable_resources method to create nested routes for all filterable associations
  filterable_resources :teams do
    resources :players, shallow: true
    resources :ratings, only: [:new, :create]
    resources :memberships, only: [:new, :create]
    get 'strength/game_attempts', to: 'strength#team_game_attempts'
  end
end
