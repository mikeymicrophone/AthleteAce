# Routes for game-related functionality
Rails.application.routes.draw do
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
  
  # Route for submitting game attempt results and retrieving game attempts
  resources :game_attempts, only: [:index, :create]
end