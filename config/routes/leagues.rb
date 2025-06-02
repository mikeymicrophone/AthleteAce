# Routes for the leagues resource
Rails.application.routes.draw do
  filterable_resources :leagues do
    resources :teams, shallow: true
    resources :players, shallow: true
    resources :conferences, shallow: true
    get 'strength/team_match', to: 'strength#team_match'
  end
end
