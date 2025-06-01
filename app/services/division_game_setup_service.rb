require 'ostruct'

class DivisionGameSetupService
  MINIMUM_VIABLE_GAME_CHOICES = 2 # Absolute minimum choices for a game to be playable
  attr_reader :difficulty, :num_choices

  # Initializes the service with a difficulty level and number of choices.
  # difficulty: :conference or :league
  # num_choices: Total number of division options to present to the user.
  def initialize(difficulty:, num_choices: 4)
    @difficulty = difficulty.to_sym
    @num_choices = num_choices
    raise ArgumentError, 'Number of choices must be at least 2' if @num_choices < 2
  end

  # Sets up a new round for the 'Guess the Division' game.
  # Returns an OpenStruct containing:
  #   - team: The Team object for the question.
  #   - choices: An array of Division objects to be presented as choices.
  #   - correct_division: The correct Division object for the team.
  #   - sport: The Sport object for the team (for display purposes).
  # Returns nil if a valid game setup cannot be achieved (e.g., no suitable teams).
  def call
    team = select_team_for_game
    return nil unless team

    correct_division = team.division # Relies on has_one :division, through: :active_membership
    
    # Ensure all required associations are present
    unless correct_division && team.conference && team.league
      Rails.logger.error "Game setup failed: Team #{team.id} (#{team.name}) missing required associations."
      Rails.logger.error "  - Division: #{correct_division&.id}"
      Rails.logger.error "  - Conference: #{team.conference&.id}"
      Rails.logger.error "  - League: #{team.league&.id}"
      return nil
    end

    # Log the sport for debugging purposes
    sport = team.sport
    Rails.logger.info "Setting up game for team #{team.name} in sport #{sport&.name || 'unknown'}"

    choices = generate_choices(team, correct_division)
    
    if choices.nil? || choices.length < MINIMUM_VIABLE_GAME_CHOICES
      Rails.logger.error "Game setup failed: Not enough viable choices generated for team #{team.id} (#{team.name})."
      Rails.logger.error "  - Minimum Required: #{MINIMUM_VIABLE_GAME_CHOICES}, Generated: #{choices&.length || 0}, Requested: #{@num_choices}"
      Rails.logger.error "  - Difficulty: #{difficulty}"
      return nil
    end

    # Log the choices for debugging
    Rails.logger.info "Generated #{choices.length} choices for team #{team.name}:"
    choices.each do |div|
      Rails.logger.info "  - #{div.name} (Conference: #{div.conference&.name}, League: #{div.conference&.league&.name})"
    end

    OpenStruct.new(
      team: team, 
      choices: choices.shuffle, 
      correct_division: correct_division,
      sport: sport
    )
  end

  private

  def select_team_for_game
    Team.joins(division: :conference).joins(:league).distinct.sample
  end

  def generate_choices(team, correct_division)
    team_league = team.league

    choice_pool_scope = case difficulty
                        when :conference
                          # Get divisions from the team's current conference.
                          # Filter these divisions to ensure they belong to conferences
                          # that are part of the team's actual league.
                          # This assumes Division has `belongs_to :conference` and Conference has `belongs_to :league`.
                          if team.conference && team_league
                            team.conference.divisions
                                .joins(conference: :league)
                                .where(conferences: { league_id: team_league.id })
                          else
                            # Fallback or error if essential associations are missing
                            Rails.logger.error "Team #{team.id} is missing conference or league for conference-difficulty game setup."
                            Division.none # Return an empty scope to prevent errors
                          end
                        when :league
                          # Get divisions directly from the team's league.
                          # This should inherently be sport-correct.
                          team_league&.divisions || Division.none
                        else
                          # Default to league difficulty if an unknown difficulty is passed.
                          Rails.logger.warn "Unknown difficulty: #{difficulty}, defaulting to league."
                          team_league&.divisions || Division.none
                        end

    return nil unless choice_pool_scope

    distractor_pool = choice_pool_scope.where.not(id: correct_division.id)
    num_distractors_to_fetch = @num_choices - 1
    distractors = distractor_pool.sample(num_distractors_to_fetch)
    all_choices = ([correct_division] + distractors).uniq
    
    return nil unless correct_division
    final_choices = ([correct_division] + distractors).compact.uniq
    final_choices.any? ? final_choices : nil
  end
end
