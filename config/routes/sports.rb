# Routes for sports hierarchy and data resources
# Note: All filterable nested routes are auto-generated via locations.rb
Rails.application.routes.draw do
  # Core sports hierarchy (index/show only - no CRUD)
  resources :sports, only: [:index, :show]
  resources :leagues, only: [:index, :show]
  resources :conferences, only: [:index, :show]
  resources :divisions, only: [:index, :show]
  resources :teams, only: [:index, :show]
  resources :players, only: [:index, :show]
  
  # Organizational structure
  resources :memberships, only: [:index, :show]
  
  # Time-based resources
  resources :seasons, only: [:index, :show]
  resources :years, only: [:index, :show]
  resources :campaigns, only: [:index, :show]
  resources :contests, only: [:index, :show]
  
  # Contract system
  resources :contracts, only: [:index, :show]
  resources :activations, only: [:index, :show]
  
  # Geographic resources
  resources :countries, only: [:index, :show]
  resources :states, only: [:index, :show]
  resources :cities, only: [:index, :show]
  resources :stadiums, only: [:index, :show]
  
  # Administrative resources
  resources :federations, only: [:index, :show]
end