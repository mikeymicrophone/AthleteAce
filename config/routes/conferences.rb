# Routes for the conferences resource
Rails.application.routes.draw do
  filterable_resources :conferences do
    resources :divisions, shallow: true
    resources :teams, only: [:index]
    get 'strength/team_match', to: 'strength#team_match'
  end
end
