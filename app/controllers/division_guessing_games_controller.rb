class DivisionGuessingGamesController < ApplicationController
  MINIMUM_VIABLE_GAME_CHOICES = 2 # Absolute minimum choices for a game to be playable
  before_action :authenticate_ace! # Ensure user is logged in

  def new
    setup_game
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def update
    setup_game
    respond_to do |format|
      format.turbo_stream
    end
  end

  # This action is now just for setting up a new question when the client calls loadNextQuestion()
  # Game attempt creation is handled via the standard GameAttemptsController
  def create
    setup_game
    
    respond_to do |format|
      format.html { redirect_to new_division_game_path }
      format.turbo_stream
    end
  end

  private

  def setup_game
    # Allow difficulty to be configurable via params
    difficulty = params[:difficulty]&.to_sym || :conference
    # Validate difficulty is one of the allowed values
    difficulty = :conference unless [:conference, :league].include?(difficulty)
    
    # Allow number of choices to be configurable
    num_choices = params[:num_choices]&.to_i || 4
    # Ensure num_choices is within a reasonable range for what the user might request
    num_choices = 4 if num_choices < 2 || num_choices > 8

    # Log useful debugging information
    Rails.logger.info "Setting up division game with difficulty: #{difficulty}, num_choices: #{num_choices}"
    
    service = DivisionGameSetupService.new(difficulty: difficulty, num_choices: num_choices)
    game_data = service.call

    if game_data.nil? || game_data.team.nil? || game_data.correct_division.nil? || game_data.choices.blank? || game_data.choices.length < MINIMUM_VIABLE_GAME_CHOICES
      error_message = "Could not set up a new game. "
      if game_data && game_data.choices && game_data.choices.length < MINIMUM_VIABLE_GAME_CHOICES
        error_message += "At least #{MINIMUM_VIABLE_GAME_CHOICES} division choices are needed, but only found #{game_data.choices.length}. "
      else
        error_message += "There might not be enough teams or divisions with the current settings. "
      end
      error_message += "Please try a different difficulty or ensure your database has sufficient data."
      
      flash[:alert] = error_message
      # Redirect to the game page without parameters to show difficulty selection, or to a specific error page
      redirect_to new_division_game_path 
      return
    end

    @team = game_data.team
    @correct_division = game_data.correct_division
    @choices = game_data.choices # Array of Division objects
    @sport = game_data.sport # Pass the sport to the view
    
    # Log successful setup with details
    Rails.logger.info "Division game setup successful with #{@choices.length} choices for team: #{@team.name} (ID: #{@team.id}), correct division: #{@correct_division.name} (ID: #{@correct_division.id}), sport: #{@sport&.name || 'unknown'})"

    # Store necessary info in session for the create action
    session[:division_game_team_id] = @team.id
    session[:division_game_correct_division_id] = @correct_division.id
    session[:division_game_difficulty] = difficulty.to_s
    session[:division_game_choice_ids] = @choices.map(&:id)
    session[:division_game_start_time] = Time.current.to_f

    # The view (new.html.erb) will display @team and @choices
  end
end
