# Routes for stadiums resource
Rails.application.routes.draw do
  filterable_resources :stadiums do
    resources :teams, shallow: true
    resources :players, shallow: true
  end
end
