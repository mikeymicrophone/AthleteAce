require 'ostruct'

class DivisionGameSetupService
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
    
    if choices.nil? || choices.length < @num_choices
      Rails.logger.error "Game setup failed: Not enough choices generated for team #{team.id} (#{team.name})."
      Rails.logger.error "  - Required: #{@num_choices}, Generated: #{choices&.length || 0}"
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

  # Selects a random team that has an active division, conference, and league.
  def select_team_for_game
    # Ensures team has an active division, that division has a conference,
    # and the team itself belongs to a league.
    # This query will find teams that have: an active membership -> a division -> a conference,
    # AND the team itself has a league_id.
    Team.joins(division: :conference).joins(:league).distinct.sample
  end

  # Generates a list of division choices including the correct division and distractors.
  def generate_choices(team, correct_division)
    team_league = team.league
    # select_team_for_game should ensure team_league and team.conference are present.

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

    # Ensure correct_division is not included in distractors initial pool
    distractor_pool = choice_pool_scope.where.not(id: correct_division.id)

    # We need num_choices - 1 distractors
    num_distractors_to_fetch = @num_choices - 1
    distractors = distractor_pool.sample(num_distractors_to_fetch)

    # If we couldn't fetch enough distractors (e.g., conference only has 1-2 other divisions)
    # this will result in fewer than num_choices options. The call method checks this.
    all_choices = ([correct_division] + distractors).uniq
    
    # The `call` method checks if choices.length < @num_choices.
    # We just need to ensure we have at least one choice (the correct one).
    # If all_choices is empty (which shouldn't happen if correct_division is always added and valid),
    # or only contains nil (also shouldn't happen), returning nil is appropriate.
    # Ensure correct_division is part of the choices if it's valid.
    return nil unless correct_division
    final_choices = ([correct_division] + distractors).compact.uniq
    
    return final_choices.any? ? final_choices : nil
  end
end
