class StrengthController < ApplicationController
  # Main dashboard for strength training
  def index
    # Load all sports, leagues, and teams for the filter dropdowns
    @sports = Sport.all
    @leagues = League.all
    @teams = Team.all
    
    # Preserve filter parameters from the form submission
    @team_id = params[:team_id]
    @sport_id = params[:sport_id]
    @league_id = params[:league_id]
    @include_inactive = params[:include_inactive]
  end

  # Multiple choice quiz for learning names
  def multiple_choice
    # Collect filter parameters
    id_collect
    
    # Create filter params hash
    filter_params = {}
    filter_params[:team_id] = @team_id if @team_id.present?
    filter_params[:sport_id] = @sport_id if @sport_id.present?
    filter_params[:league_id] = @league_id if @league_id.present?
    filter_params[:include_inactive] = @include_inactive if @include_inactive.present?
    
    # Fetch players using explicit filter parameters
    @players = fetch_players_with_params(filter_params)
    
    # If no players found, clear filters and try again
    if @players.empty?
      flash.now[:alert] = "No players found with the selected filters. Showing all players instead."
      @players = Player.limit(50).to_a
    end
    
    @correct_player = @players.sample
    @options = [@correct_player] + (@players - [@correct_player]).sample([3, @players.size - 1].min)
    @options.shuffle!
  end

  # Phased repetition for spaced learning
  def phased_repetition
    # Log incoming parameters for debugging
    Rails.logger.debug "PHASED REPETITION PARAMS: #{params.inspect}"
    
    # Collect and process filter parameters
    id_collect
    
    # Force debug logging to ensure we can see what's happening
    Rails.logger.debug "AFTER ID_COLLECT - Team ID: #{@team_id.inspect} (#{@team_id.class})"
    
    # Double-check team_id is properly set
    if @team_id.present?
      # Explicitly verify the team exists and has players
      team = Team.find_by(id: @team_id)
      if team
        player_count = Player.where(team_id: @team_id).count
        Rails.logger.debug "TEAM FOUND: #{team.territory} #{team.mascot} with #{player_count} players"
      else
        Rails.logger.warn "TEAM NOT FOUND for ID: #{@team_id}"
        @team_id = nil # Reset if team doesn't exist
      end
    end
    
    # Fetch players based on filters - this time with explicit team_id parameter
    filter_params = {}
    filter_params[:team_id] = @team_id if @team_id.present?
    filter_params[:sport_id] = @sport_id if @sport_id.present?
    filter_params[:league_id] = @league_id if @league_id.present?
    filter_params[:include_inactive] = @include_inactive if @include_inactive.present?
    
    Rails.logger.debug "USING FILTER PARAMS: #{filter_params.inspect}"
    
    # Use the filter params directly instead of relying on instance variables
    @players = fetch_players_with_params(filter_params)
    Rails.logger.debug "PLAYERS FOUND: #{@players.count}"
    
    # If no players found with the current filters, clear filters and try again
    if @players.empty?
      flash.now[:alert] = "No players found with the selected filters. Showing all players instead."
      @team_id = @sport_id = @league_id = nil
      @players = Player.limit(50).to_a
      Rails.logger.debug "AFTER CLEARING FILTERS, players found: #{@players.count}"
    end
    
    # Get a random player from the filtered list
    @current_player = @players.sample
    Rails.logger.debug "SELECTED PLAYER: #{@current_player.inspect}"
    
    # In a real implementation, you would track the user's progress
    # and show players based on their repetition schedule
    @phase = params[:phase].present? ? params[:phase].to_i : 1
  end

  # Image-based learning
  def images
    # Collect filter parameters
    id_collect
    
    # Create filter params hash
    filter_params = {}
    filter_params[:team_id] = @team_id if @team_id.present?
    filter_params[:sport_id] = @sport_id if @sport_id.present?
    filter_params[:league_id] = @league_id if @league_id.present?
    filter_params[:include_inactive] = @include_inactive if @include_inactive.present?
    
    # Fetch players using explicit filter parameters
    @players = fetch_players_with_params(filter_params).select { |p| p.photo_urls.present? }
    
    # If no players found, clear filters and try again
    if @players.empty?
      flash.now[:alert] = "No players with photos found with the selected filters. Showing all players with photos instead."
      @players = Player.where.not(photo_urls: [nil, '']).limit(50).to_a
    end
    
    @current_player = @players.sample
  end

  # Cipher-based learning (scrambled names)
  def ciphers
    # Collect filter parameters
    id_collect
    
    # Create filter params hash
    filter_params = {}
    filter_params[:team_id] = @team_id if @team_id.present?
    filter_params[:sport_id] = @sport_id if @sport_id.present?
    filter_params[:league_id] = @league_id if @league_id.present?
    filter_params[:include_inactive] = @include_inactive if @include_inactive.present?
    
    # Fetch players using explicit filter parameters
    @players = fetch_players_with_params(filter_params)
    
    # If no players found, clear filters and try again
    if @players.empty?
      flash.now[:alert] = "No players found with the selected filters. Showing all players instead."
      @players = Player.limit(50).to_a
    end
    
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
    # Start with all players but eager load associations for better performance
    players = Player.includes(:team, team: :league)
    
    # Apply team filter if provided - check both params and instance variables
    team_id_value = params[:team_id].presence || @team_id.presence
    if team_id_value.present?
      # Convert to integer and ensure it's not zero or nil
      team_id = team_id_value.to_i
      if team_id > 0
        players = players.where(team_id: team_id)
        Rails.logger.debug "FILTERING BY TEAM_ID: #{team_id}, found #{players.count} players"
        
        # Verify we actually found players with this team_id
        if players.count == 0
          Rails.logger.warn "No players found for team_id: #{team_id}! Check if this team exists."
          # Try to find the team to confirm it exists
          team = Team.find_by(id: team_id)
          Rails.logger.debug team ? "Team exists: #{team.territory} #{team.mascot}" : "Team with ID #{team_id} does not exist!"
        end
      else
        Rails.logger.warn "Invalid team_id value: #{team_id_value}"
      end
    end
    
    # Apply sport filter if provided
    sport_id_value = params[:sport_id].presence || @sport_id.presence
    if sport_id_value.present?
      sport_id = sport_id_value.to_i
      if sport_id > 0
        players = players.joins(team: :league).where(leagues: { sport_id: sport_id })
        Rails.logger.debug "Filtering by sport_id: #{sport_id}, found #{players.count} players"
      end
    end
    
    # Apply league filter if provided
    league_id_value = params[:league_id].presence || @league_id.presence
    if league_id_value.present?
      league_id = league_id_value.to_i
      if league_id > 0
        players = players.joins(team: :league).where(leagues: { id: league_id })
        Rails.logger.debug "Filtering by league_id: #{league_id}, found #{players.count} players"
      end
    end
    
    # Limit to active players by default unless specifically requesting inactive
    include_inactive_value = params[:include_inactive].presence || @include_inactive.presence
    unless include_inactive_value == 'true'
      players = players.where(active: true).or(players.where(active: nil))
      Rails.logger.debug "Filtering by active status, found #{players.count} players"
    end
    
    # Make sure we're getting a collection, not a relation
    players = players.to_a
    
    # Return a reasonable number of players for the exercise (max 50)
    # but ensure we return all players if there are fewer than 50
    Rails.logger.debug "Total players after filtering: #{players.count}"
    
    # If we have no players after filtering, log a warning
    if players.empty?
      Rails.logger.warn "No players found after applying filters!"
      return Player.limit(50).to_a
    end
    
    players.sample([players.count, 50].min)
  end

  def id_collect
    # Collect and normalize filter parameters
    @team_id = params[:team_id].presence
    @sport_id = params[:sport_id].presence
    @league_id = params[:league_id].presence
    @include_inactive = params[:include_inactive].presence
    
    # Convert IDs to integers if they're present and valid
    @team_id = @team_id.to_i if @team_id.present? && @team_id.to_i > 0
    @sport_id = @sport_id.to_i if @sport_id.present? && @sport_id.to_i > 0
    @league_id = @league_id.to_i if @league_id.present? && @league_id.to_i > 0
    
    # Log the collected parameters for debugging
    Rails.logger.debug "ID COLLECT: team_id=#{@team_id.inspect}, sport_id=#{@sport_id.inspect}, league_id=#{@league_id.inspect}"
    
    # Verify team exists if team_id is provided
    if @team_id.present? && @team_id.to_i > 0
      team = Team.find_by(id: @team_id)
      if team
        Rails.logger.debug "Found team: #{team.territory} #{team.mascot}"
      else
        Rails.logger.warn "Team with ID #{@team_id} not found!"
        @team_id = nil # Reset if team doesn't exist
      end
    end
  end
  
  # Fetch players using explicit filter parameters
  def fetch_players_with_params(filter_params)
    # Start with all players but eager load associations for better performance
    players = Player.includes(:team, team: :league)
    
    # Apply team filter if provided
    if filter_params[:team_id].present?
      team_id = filter_params[:team_id].to_i
      if team_id > 0
        players = players.where(team_id: team_id)
        Rails.logger.debug "EXPLICIT FILTER: team_id=#{team_id}, found #{players.count} players"
      end
    end
    
    # Apply sport filter if provided
    if filter_params[:sport_id].present?
      sport_id = filter_params[:sport_id].to_i
      if sport_id > 0
        players = players.joins(team: :league).where(leagues: { sport_id: sport_id })
      end
    end
    
    # Apply league filter if provided
    if filter_params[:league_id].present?
      league_id = filter_params[:league_id].to_i
      if league_id > 0
        players = players.joins(team: :league).where(leagues: { id: league_id })
      end
    end
    
    # Limit to active players by default unless specifically requesting inactive
    unless filter_params[:include_inactive] == 'true'
      players = players.where(active: true).or(players.where(active: nil))
    end
    
    # Make sure we're getting a collection, not a relation
    players = players.to_a
    
    # If no players found after filtering, return an empty array
    if players.empty?
      Rails.logger.warn "No players found with filters: #{filter_params.inspect}"
      return []
    end
    
    # Return a reasonable number of players (max 50)
    players.sample([players.count, 50].min)
  end
end
