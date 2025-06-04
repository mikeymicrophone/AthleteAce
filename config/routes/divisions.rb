# Routes for the divisions resource
Rails.application.routes.draw do
  filterable_resources :divisions do
    resources :teams, shallow: true
    resources :ratings, only: [:new, :create]
    get 'strength/team_match', to: 'strength#team_match'
  end

  filterable_resources :memberships
end
