# Split routes into smaller files that can be loaded individually
require_relative 'routes/filterable'

Rails.application.routes.draw do
  resources :campaigns, only: [:index, :show]
  resources :contests, only: [:index, :show]
  resources :seasons, only: [:index, :show] do
    resources :campaigns, only: [:index, :show]
  end
  resources :years, only: [:index, :show]
  # Load modular route files
  draw :ratings
  draw :locations
  devise_for :aces
  # Strength training routes for learning athlete names
  get "strength" => "strength#index"
  get "strength/multiple_choice" => "strength#multiple_choice"
  get "strength/phased_repetition" => "strength#phased_repetition"
  get "strength/images" => "strength#images"
  get "strength/ciphers" => "strength#ciphers"
  get "strength/team_match" => "strength#team_match"
  get "strength/game_attempts" => "strength#game_attempts"
  post "strength/check_answer" => "strength#check_answer", as: :check_answer

  # Division Guessing Game
  get "play/guess-the-division" => "division_guessing_games#new", as: :new_division_game
  post "play/guess-the-division" => "division_guessing_games#create", as: :create_division_game_attempt
  patch "play/guess-the-division" => "division_guessing_games#update", as: :update_division_game
  resources :achievements do
    collection do
      get :target_options
    end
  end
  
  resources :quests do
    resources :highlights
    resources :goals, only: [:create]
    collection do
      get :random
    end
  end
  
  # Route for submitting game attempt results and retrieving game attempts
  resources :game_attempts, only: [:index, :create]
  
  resources :highlights, only: [:new, :create]
  
  resources :goals, except: [:create, :new]
  resources :federations
  
  # League organization
  resources :conferences do
    resources :divisions, shallow: true
    resources :teams, only: [:index]
    get 'strength/team_match', to: 'strength#team_match'
  end
  
  resources :divisions do
    resources :teams, shallow: true
    resources :ratings, only: [:new, :create]
    get 'strength/team_match', to: 'strength#team_match'
  end
  
  resources :memberships
  
  resources :teams do
    resources :players, shallow: true
    resources :ratings, only: [:new, :create]
    resources :memberships, only: [:new, :create]
    resources :campaigns, only: [:index, :show]
    get 'strength/game_attempts', to: 'strength#team_game_attempts'
  end
  resources :countries do
    resources :leagues, shallow: true
    resources :teams, shallow: true
    resources :players, shallow: true
    resources :stadiums, shallow: true
    resources :cities, shallow: true do
      resources :stadiums, shallow: true
      resources :teams, shallow: true
      resources :players, shallow: true
    end
    resources :states, shallow: true
  end
  resources :stadiums do
    resources :teams, shallow: true
    resources :players, shallow: true
  end
  resources :cities do
    resources :leagues, shallow: true
    resources :teams, shallow: true
    resources :players, shallow: true
    get 'strength/team_match', to: 'strength#team_match'
  end
  resources :states do
    resources :teams, shallow: true
    resources :players, shallow: true
    resources :cities, shallow: true
    resources :stadiums, shallow: true
    get 'strength/team_match', to: 'strength#team_match'
  end
  resources :leagues do
    resources :teams, shallow: true
    resources :players, shallow: true
    get 'strength/team_match', to: 'strength#team_match'
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

  namespace :strength do
    get 'team_match', to: 'team_match#show'
    get 'game_attempts', to: 'strength#game_attempts'
  end
end
