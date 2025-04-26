Rails.application.routes.draw do
  resources :achievements
  resources :quests do
    resources :achievements
  end
  resources :federations
  resources :players
  resources :teams
  resources :countries do
    resources :leagues, shallow: true
    resources :teams, shallow: true
    resources :players, shallow: true
    resources :stadia, shallow: true
    resources :cities, shallow: true do
      resources :stadia, shallow: true
      resources :teams, shallow: true
      resources :players, shallow: true
    end
    resources :states, shallow: true
  end
  resources :stadia do
    resources :teams, shallow: true
    resources :players, shallow: true
  end
  resources :cities do
    resources :leagues, shallow: true
    resources :teams, shallow: true
    resources :players, shallow: true
  end
  resources :states do
    resources :teams, shallow: true
    resources :players, shallow: true
    resources :cities, shallow: true
    resources :stadia, shallow: true
  end
  resources :leagues do
    resources :teams, shallow: true
    resources :players, shallow: true
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  root "players#index"
  resources :sports do
    resources :leagues, shallow: true
    resources :teams, shallow: true
    resources :players, shallow: true
  end
end
