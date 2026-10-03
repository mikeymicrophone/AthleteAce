# Routes for game-related functionality
Rails.application.routes.draw do
  # Strength training routes for learning athlete names
  get "strength" => "play#index"
  resources :game_rounds, path: "play/rounds", only: [:new, :create, :show] do
    member do
      post :answer
      post :advance
      post :pause
      post :resume
      post :drill
      get :summary
    end
  end
  get "strength/multiple_choice" => "strength#multiple_choice"
  get "strength/phased_repetition" => "strength#phased_repetition"
  get "strength/images" => "strength#images"
  get "strength/ciphers" => "strength#ciphers"
  get "strength/team_match" => "strength#team_match"
  get "strength/game_attempts" => "strength#game_attempts"
  get "strength/teams/:team_id/game_attempts" => "strength#team_game_attempts", as: :team_strength_game_attempts
  post "strength/check_answer" => "strength#check_answer", as: :check_answer

  # Division Guessing Game
  get "play/guess-the-division" => "division_guessing_games#new", as: :new_division_game
  post "play/guess-the-division" => "division_guessing_games#create", as: :create_division_game_attempt
  patch "play/guess-the-division" => "division_guessing_games#update", as: :update_division_game
  
  # Route for submitting game attempt results and retrieving game attempts
  resources :game_attempts, only: [:index, :create]
end
