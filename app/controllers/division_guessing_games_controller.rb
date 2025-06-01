class DivisionGuessingGamesController < ApplicationController
  MINIMUM_VIABLE_GAME_CHOICES = 2
  before_action :authenticate_ace!

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
    difficulty = params[:difficulty]&.to_sym || :conference
    difficulty = :conference unless [:conference, :league].include?(difficulty)
    num_choices = params[:num_choices]&.to_i || 4
    num_choices = 4 if num_choices < 2 || num_choices > 8

    service = DivisionGameSetupService.new(difficulty: difficulty, num_choices: num_choices)
    game_data = service.call

    if game_data.nil? || game_data.team.nil? || game_data.correct_division.nil? || game_data.choices.blank? || game_data.choices.length < MINIMUM_VIABLE_GAME_CHOICES
      flash[:alert] = "Could not set up a new game. Please try a different difficulty or ensure your database has sufficient data."
      redirect_to new_division_game_path 
      return
    end

    @team = game_data.team
    @correct_division = game_data.correct_division
    @choices = game_data.choices
    @sport = game_data.sport
    
    session[:division_game_team_id] = @team.id
    session[:division_game_correct_division_id] = @correct_division.id
    session[:division_game_difficulty] = difficulty.to_s
    session[:division_game_choice_ids] = @choices.map(&:id)
    session[:division_game_start_time] = Time.current.to_f
  end
end
