class DivisionGuessingGamesController < ApplicationController
  before_action :authenticate_ace! # Ensure user is logged in

  def new
    # Allow difficulty to be configurable via params
    difficulty = params[:difficulty]&.to_sym || :conference
    # Validate difficulty is one of the allowed values
    difficulty = :conference unless [:conference, :league].include?(difficulty)
    
    # Allow number of choices to be configurable
    num_choices = params[:num_choices]&.to_i || 4
    # Ensure num_choices is within a reasonable range
    num_choices = 4 if num_choices < 2 || num_choices > 8

    service = DivisionGameSetupService.new(difficulty: difficulty, num_choices: num_choices)
    game_data = service.call

    if game_data.nil? || game_data.team.nil? || game_data.correct_division.nil? || game_data.choices.blank? || game_data.choices.length < num_choices
      # Provide more specific error message based on difficulty
      error_message = "Could not set up a new game with #{difficulty} difficulty. "
      error_message += case difficulty
                      when :conference
                        "There might not be enough divisions in the same conference and league. Try the 'League' difficulty instead."
                      when :league
                        "There might not be enough divisions in the same league. Please ensure your database has teams with active divisions."
                      else
                        "There might not be enough teams or divisions with the current settings. Please try again later."
                      end
      
      flash[:alert] = error_message
      redirect_to new_division_game_path # Redirect to the game page without parameters to show difficulty selection
      return
    end

    @team = game_data.team
    @choices = game_data.choices # Array of Division objects
    @sport = game_data.sport # Pass the sport to the view

    # Store necessary info in session for the create action
    session[:division_game_team_id] = @team.id
    session[:division_game_correct_division_id] = game_data.correct_division.id
    session[:division_game_difficulty] = difficulty.to_s
    session[:division_game_choice_ids] = @choices.map(&:id)
    session[:division_game_start_time] = Time.current.to_f

    # The view (new.html.erb) will display @team and @choices
  end

  def create
    # Retrieve data from session and params
    team_id = session.delete(:division_game_team_id)
    correct_division_id = session.delete(:division_game_correct_division_id)
    difficulty_level = session.delete(:division_game_difficulty)
    options_presented_ids = session.delete(:division_game_choice_ids) || []
    start_time = session.delete(:division_game_start_time)

    # Get the guessed division ID directly from params
    # This works with both form submissions and direct link clicks
    guessed_division_id = params[:guessed_division_id]

    # Basic validation for presence of essential data
    unless team_id && correct_division_id && difficulty_level && guessed_division_id && start_time
      flash[:alert] = "An error occurred with your game session. Please start a new game."
      redirect_to new_division_game_path
      return
    end

    time_elapsed_ms = ((Time.current.to_f - start_time.to_f) * 1000).to_i

    team = Team.find_by(id: team_id)
    correct_division = Division.find_by(id: correct_division_id)
    guessed_division = Division.find_by(id: guessed_division_id)

    unless team && correct_division && guessed_division
      flash[:alert] = "Invalid game data encountered. Please start a new game."
      redirect_to new_division_game_path
      return
    end

    is_correct = (correct_division.id == guessed_division.id)

    # Create GameAttempt record
    # Note: `options_presented` and `time_elapsed_ms` are required by the GameAttempt model's schema
    game_attempt = current_ace.game_attempts.build(
      subject_entity: team,
      target_entity: correct_division,
      chosen_entity: guessed_division,
      is_correct: is_correct,
      game_type: "guess_the_division",
      difficulty_level: difficulty_level,
      options_presented: options_presented_ids, # Array of Division IDs
      time_elapsed_ms: time_elapsed_ms
    )

    if game_attempt.save
      if is_correct
        flash[:notice] = "Correct! Well done."
      else
        flash[:alert] = "Incorrect. The correct division for #{team.name} was #{correct_division.name}."
      end
    else
      flash[:error] = "Could not save your attempt: #{game_attempt.errors.full_messages.join(', ')}"
    end

    redirect_to new_division_game_path
  end
end
