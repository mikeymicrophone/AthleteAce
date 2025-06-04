# Routes for location-based resources (countries, states, cities)
Rails.application.routes.draw do
  # Countries
  filterable_resources :countries
  
  # States
  filterable_resources :states
  
  # Cities
  filterable_resources :cities
end
