# Routes for location-based resources (countries, states, cities)
Rails.application.routes.draw do
  # Countries
  filterable_resources :countries do
    resources :leagues, shallow: true
    resources :teams, shallow: true
    resources :players, shallow: true
    resources :stadiums, shallow: true
    resources :states, shallow: true
    resources :cities, shallow: true
  end
  
  # States
  filterable_resources :states do
    resources :teams, shallow: true
    resources :players, shallow: true
    resources :cities, shallow: true
    resources :stadiums, shallow: true
    resources :memberships, shallow: true
    resources :divisions, shallow: true
    resources :conferences, shallow: true
    resources :sports, shallow: true
    get 'strength/team_match', to: 'strength#team_match'
  end
  
  # Cities
  filterable_resources :cities #do
#     resources :leagues, shallow: true
#     resources :teams, shallow: true
#     resources :players, shallow: true
#     resources :stadiums, shallow: true
#     resources :memberships, shallow: true
#     resources :divisions, shallow: true
#     resources :conferences, shallow: true
#     resources :sports, shallow: true
#     get 'strength/team_match', to: 'strength#team_match'
#   end
end
