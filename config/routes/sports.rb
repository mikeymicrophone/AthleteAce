# Routes for sports resource
Rails.application.routes.draw do
  filterable_resources :sports do
    resources :leagues, shallow: true
    resources :teams, shallow: true
    resources :players, shallow: true
  end
end
