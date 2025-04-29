class StrengthController < ApplicationController
  # Main dashboard for strength training
  def index
    @sports = Sport.all
    @leagues = League.all
    @teams = Team.all
  end

  # Multiple choice quiz for learning names
  def multiple_choice
    @players = fetch_players
    @correct_player = @players.sample
    @options = [@correct_player] + (@players - [@correct_player]).sample(3)
    @options.shuffle!
  end

  # Phased repetition for spaced learning
  def phased_repetition
    @players = fetch_players
    @current_player = @players.sample
    
    # In a real implementation, you would track the user's progress
    # and show players based on their repetition schedule
    @phase = params[:phase].present? ? params[:phase].to_i : 1
  end

  # Image-based learning
  def images
    @players = fetch_players.select { |p| p.photo_urls.present? }
    @current_player = @players.sample
  end

  # Cipher-based learning (scrambled names)
  def ciphers
    @players = fetch_players
    @current_player = @players.sample
    
    # Create a simple cipher by scrambling the letters
    full_name = "#{@current_player.first_name} #{@current_player.last_name}"
    @scrambled_name = full_name.chars.shuffle.join
  end
  
  # Method to handle quiz submissions
  def check_answer
    @player = Player.find(params[:player_id])
    @selected_id = params[:selected_id].to_i
    @correct = (@player.id == @selected_id)
    
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to strength_multiple_choice_path, notice: @correct ? "Correct!" : "Incorrect. Try again!" }
    end
  end
  
  private
  
  # Fetch players based on filters
  def fetch_players
    players = Player.all
    
    # Apply filters if provided
    players = players.where(team_id: params[:team_id]) if params[:team_id].present?
    players = players.joins(team: :league).where(leagues: { sport_id: params[:sport_id] }) if params[:sport_id].present?
    players = players.joins(team: :league).where(leagues: { id: params[:league_id] }) if params[:league_id].present?
    
    # Limit to active players by default unless specifically requesting inactive
    players = players.where(active: true) unless params[:include_inactive] == 'true'
    
    # Return a reasonable number of players for the exercise
    players.limit(50)
  end
end
