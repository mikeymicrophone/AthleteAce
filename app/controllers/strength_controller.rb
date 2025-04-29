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
    
    if @players.present?
      @correct_player = @players.sample
      @options = [@correct_player] + (@players - [@correct_player]).sample(3)
      @options.shuffle!
    else
      flash[:alert] = "No players found matching your criteria. Please adjust your filters."
      redirect_to strength_path
    end
  end

  # Phased repetition for spaced learning
  def phased_repetition
    @players = fetch_players
    
    if @players.present?
      @current_player = @players.sample
      # In a real implementation, you would track the user's progress
      # and show players based on their repetition schedule
      @phase = params[:phase].present? ? params[:phase].to_i : 1
    else
      flash[:alert] = "No players found matching your criteria. Please adjust your filters."
      redirect_to strength_path
    end
  end

  # Image-based learning
  def images
    @players = fetch_players.select { |p| p.photo_urls.present? }
    
    if @players.present?
      @current_player = @players.sample
    else
      flash[:alert] = "No players with photos found matching your criteria. Please adjust your filters."
      redirect_to strength_path
    end
  end

  # Cipher-based learning (scrambled names)
  def ciphers
    @players = fetch_players
    
    if @players.present?
      @current_player = @players.sample
      
      # Create a simple cipher by scrambling the letters
      full_name = "#{@current_player.first_name} #{@current_player.last_name}"
      @scrambled_name = full_name.chars.shuffle.join
    else
      flash[:alert] = "No players found matching your criteria. Please adjust your filters."
      redirect_to strength_path
    end
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
    # Start with all players
    players = Player.all
    Rails.logger.debug "Initial player count: #{players.count}"
    
    # Use pry for interactive debugging
    # binding.pry
    
    # Apply team filter if provided
    if params[:team_id].present?
      Rails.logger.debug "Filtering by team_id: #{params[:team_id]}"
      players = players.where(team_id: params[:team_id])
      Rails.logger.debug "After team filter, player count: #{players.count}"
    end
    
    # Apply sport filter if provided
    if params[:sport_id].present?
      Rails.logger.debug "Filtering by sport_id: #{params[:sport_id]}"
      players = players.joins(team: :league).where(leagues: { sport_id: params[:sport_id] })
      Rails.logger.debug "After sport filter, player count: #{players.count}"
    end
    
    # Apply league filter if provided
    if params[:league_id].present?
      Rails.logger.debug "Filtering by league_id: #{params[:league_id]}"
      players = players.joins(team: :league).where(leagues: { id: params[:league_id] })
      Rails.logger.debug "After league filter, player count: #{players.count}"
    end
    
    # Check for nil team associations
    nil_team_count = Player.where(team_id: nil).count
    Rails.logger.debug "Players with nil team_id: #{nil_team_count}"
    
    # Limit to active players by default unless specifically requesting inactive
    # players = players.where(active: true) unless params[:include_inactive] == 'true'
    
    # Return a reasonable number of players for the exercise
    final_players = players.limit(50)
    Rails.logger.debug "Final player count (after limit): #{final_players.count}"
    final_players
  end
end
