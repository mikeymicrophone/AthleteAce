class StrengthController < ApplicationController
  before_action :authenticate_ace!, except: [:index]
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
    filter_params = strength_filter_params
    @players = fetch_players_with_params(filter_params)
    
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
    Rails.logger.debug "PHASED REPETITION PARAMS: #{params.inspect}"
    
    # Collect and process filter parameters
    id_collect
    
    # Force debug logging to ensure we can see what's happening
    Rails.logger.debug "AFTER ID_COLLECT - Team ID: #{@team_id.inspect} (#{@team_id.class})"
    
    # Double-check team_id is properly set
    if @team_id.present?
      team = Team.find_by(id: @team_id)
      if team
        player_count = Player.where(team_id: @team_id).count
        Rails.logger.debug "TEAM FOUND: #{team.territory} #{team.mascot} with #{player_count} players"
      else
        Rails.logger.warn "TEAM NOT FOUND for ID: #{@team_id}"
        @team_id = nil # Reset if team doesn't exist
      end
    end
    
    filter_params = strength_filter_params
    Rails.logger.debug "USING FILTER PARAMS: #{filter_params.inspect}"
    
    @players = fetch_players_with_params(filter_params)
    Rails.logger.debug "PLAYERS FOUND: #{@players.count}"
    
    if @players.empty?
      flash.now[:alert] = "No players found with the selected filters. Showing all players instead."
      @team_id = @sport_id = @league_id = nil
      @players = Player.limit(50).to_a
      Rails.logger.debug "AFTER CLEARING FILTERS, players found: #{@players.count}"
    end
    
    @current_player = @players.sample
    Rails.logger.debug "SELECTED PLAYER: #{@current_player.inspect}"
    
    @phase = params[:phase].present? ? params[:phase].to_i : 1
  end

  # Image-based learning
  def images
    filter_params = strength_filter_params
    @players = fetch_players_with_params(filter_params).select { |p| p.photo_urls.present? }
    
    if @players.empty?
      @players = Player.where.not(photo_urls: [nil, '']).limit(50).to_a
    end
    
    @current_player = @players.sample
  end

  # Team matching game
  def team_match
    id_collect

    Rails.logger.debug "TEAM_MATCH DEBUG:"
    Rails.logger.debug "  params[:team_id] = #{params[:team_id].inspect}"
    Rails.logger.debug "  @team_id = #{@team_id.inspect}"

    filter_params = strength_filter_params.to_h.symbolize_keys
    Rails.logger.debug "  filter_params = #{filter_params.inspect}"
    
    @parent = parent_scope

    # If we have a specific scope (team, league, conference, etc)
    if @parent.present?
      Rails.logger.debug "TEAM MATCH: Parent scope found: #{@parent.class.name} ##{@parent.id}"
      
      # Get teams based on the parent scope
      # Convert to array immediately to avoid readonly association issues
      if @parent.is_a?(Team)
        teams_pool = @parent.league.teams.to_a
      elsif @parent.is_a?(Conference) || @parent.is_a?(League)
        teams_pool = @parent.teams.to_a
      else
        teams_pool = @parent.teams.to_a
      end
      
      return redirect_back(fallback_location: root_path, alert: "No teams found in this scope.") if teams_pool.empty?
      
      # Important: Restrict to ONLY these teams
      filter_params[:team_ids] = teams_pool.map(&:id)
      Rails.logger.debug "TEAM MATCH: Restricting to teams: #{filter_params[:team_ids]}"
    elsif ace_signed_in? && no_scope_specified? &&
          filter_params[:team_id].blank? && filter_params[:sport_id].blank? && filter_params[:league_id].blank?
      # No scope specified, use quest teams for logged-in users
      quest_teams = current_ace.active_goals.flat_map { |g| g.quest.associated_teams }.uniq
      unless quest_teams.empty?
        cross_sport = params[:cross_sport] == 'true'
        teams_pool  = cross_sport ? quest_teams : quest_teams.select { |t| t.sport.id == quest_teams.first.sport.id }
        filter_params[:team_ids] = teams_pool.map(&:id) if teams_pool.present?
        Rails.logger.debug "TEAM MATCH: Using quest teams: #{filter_params[:team_ids]}"
      end
    end

    # Fetch players based on the filters
    players = PlayerSearch.new(filter_params).call
    Rails.logger.debug "TEAM MATCH: Found #{players.size} players with filter params: #{filter_params}"

    if players.empty?
      Rails.logger.debug "TEAM MATCH: No players found with filtered teams, using sample"
      players = Player.sampled(50)
    end
    
    # Select a random player for the quiz
    @current_player = players.sample
    Rails.logger.debug "TEAM MATCH: Selected player: #{@current_player.name} (Team: #{@current_player.team.mascot})"
    
    # Double-check that the player's team is in our pool
    unless filter_params[:team_ids].present? && filter_params[:team_ids].include?(@current_player.team_id)
      Rails.logger.error "TEAM MATCH: Player's team not in teams_pool! Re-selecting a player."
      
      # Instead of modifying the teams_pool, we'll re-select a player from the filtered pool
      filtered_players = filter_params[:team_ids].present? ? Player.where(team_id: filter_params[:team_ids]).sampled(50) : []
      
      if filtered_players.any?
        # If we have players in the filtered pool, select one of those
        @current_player = filtered_players.sample
        Rails.logger.debug "TEAM MATCH: Re-selected player: #{@current_player.name} (Team: #{@current_player.team.mascot})"
      else
        # As a fallback, keep the current player but create a new teams_pool that includes their team
        Rails.logger.debug "TEAM MATCH: No players in filtered pool, keeping current player and adjusting pool"
        
        # If we have a specific parent scope, respect it when building the pool
        if @parent.is_a?(Conference)
          # For conference, use only teams from that conference plus the player's team
          pool = @parent.teams.to_a
          pool << @current_player.team unless pool.include?(@current_player.team)
        elsif @parent.is_a?(League)
          # For league, use only teams from that league plus the player's team
          pool = @parent.teams.to_a
          pool << @current_player.team unless pool.include?(@current_player.team)
        else
          # Default: use teams from the player's league
          pool = @current_player.team.league.teams.to_a
        end
        
        # Update the teams_pool
        teams_pool = pool
      end
    end
    
    # Define the pool of teams to choose from for the quiz
    # If we have a teams_pool and the player's team is in it, use that pool
    # Otherwise, ensure we at least restrict to teams in the same league as the player
    if teams_pool.present? && teams_pool.map(&:id).include?(@current_player.team_id)
      pool = teams_pool
      Rails.logger.debug "TEAM MATCH: Using existing teams_pool for choices"
    else
      # If the player doesn't belong to our filter, make sure we at least stay in the same league/conference
      if @parent.is_a?(Conference)
        # If we're filtering by conference, ensure we only show teams from that conference
        pool = @parent.teams
        Rails.logger.debug "TEAM MATCH: Restricting pool to conference teams: #{pool.map(&:mascot)}"
      elsif @parent.is_a?(League)
        # If we're filtering by league, ensure we only show teams from that league
        pool = @parent.teams
        Rails.logger.debug "TEAM MATCH: Restricting pool to league teams: #{pool.map(&:mascot)}"
      else
        # Default fallback - use teams from the player's league
        pool = @current_player.team.league.teams
        Rails.logger.debug "TEAM MATCH: Using player's league teams for pool"
      end
    end
    
    round = TeamMatchRound.new(player: @current_player, pool: pool)
    @team_choices = round.choices
    @correct_team = @current_player.team
    
    # Debug the final choices
    Rails.logger.debug "TEAM MATCH: Final team choices: #{@team_choices.map(&:mascot)}"
    Rails.logger.debug "TEAM MATCH: Correct team: #{@correct_team.mascot}"
    
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  # Cipher-based learning (scrambled names)
  def ciphers
    filter_params = strength_filter_params
    @players = fetch_players_with_params(filter_params)
    
    if @players.empty?
      flash.now[:alert] = "No players found with the selected filters. Showing all players instead."
      @players = Player.limit(50).to_a
    end
    
    @current_player = @players.sample
    
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
  
  def game_attempts
    @game_attempts = current_ace.game_attempts.order(created_at: :desc)
  end

  # Team-specific game attempts grouped by player
  def team_game_attempts
    @team = Team.find(params[:team_id])
    
    # Find all game attempts where this team was the target
    @attempts_by_player = {}
    @player_stats = {}
    
    # Get all attempts for this team
    attempts = current_ace.game_attempts.where(target_entity_type: 'Team', target_entity_id: @team.id)
    
    # Group attempts by subject (player)
    player_attempts = attempts.group_by(&:subject_entity_id)
    
    # For each player, calculate stats and group their attempts
    player_attempts.each do |player_id, player_attempts_array|
      player = Player.find(player_id)
      
      # Store the player's attempts
      @attempts_by_player[player] = player_attempts_array
      
      # Calculate stats
      total_attempts = player_attempts_array.size
      correct_attempts = player_attempts_array.count(&:correct?)
      
      # Calculate recent stats (last week)
      one_week_ago = 1.week.ago
      recent_attempts = player_attempts_array.select { |a| a.created_at >= one_week_ago }
      recent_total = recent_attempts.size
      recent_correct = recent_attempts.count(&:correct?)
      
      @player_stats[player] = {
        total_attempts: total_attempts,
        correct_attempts: correct_attempts,
        accuracy: total_attempts > 0 ? (correct_attempts.to_f / total_attempts * 100).round : 0,
        recent_total: recent_total,
        recent_correct: recent_correct,
        recent_accuracy: recent_total > 0 ? (recent_correct.to_f / recent_total * 100).round : 0
      }
    end
    
    # Sort players by name
    @players = @attempts_by_player.keys.sort_by(&:full_name)
  end
  
  private
  
  def no_scope_specified?
    params[:division_id].blank? && params[:conference_id].blank? && params[:league_id].blank? && params[:city_id].blank? && params[:state_id].blank? && params[:team_id].blank?
  end

  # Strong parameter helper
  def strength_filter_params
    params.permit(:team_id, :conference_id, :division_id, :sport_id, :league_id, :include_inactive, :cross_sport, team_ids: [])
  end

  FILTER_PARENTS = {
    division_id:   Division,
    conference_id: Conference,
    city_id:       City,
    state_id:      State,
    league_id:     League,
    sport_id:      Sport,
    country_id:    Country,
    team_id:       Team
  }.freeze

  # Determine the parent scope (division, conference, etc.) from params
  def parent_scope
    FILTER_PARENTS.each do |param, model|
      return model.find(params[param]) if params[param].present?
    end
    nil
  end

  # Coerce param value to int, returning nil for blank/invalid
  def int_param(key)
    value = params[key].presence
    value.to_i.positive? ? value.to_i : nil
  end

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
