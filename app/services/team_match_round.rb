# frozen_string_literal: true

# TeamMatchRound builds a single round of the team–player matching game.
# It guarantees that the correct team is included in the choices array.
class TeamMatchRound
  attr_reader :player

  def initialize(player:, pool:)
    @player = player
    @pool   = pool.to_a
    build_choices
  end

  # Returns an array of 4 teams: the correct team plus 3 distractors, shuffled.
  def choices
    @choices
  end

  private

  def build_choices
    distractors = (@pool - [player.team]).sample(3)
    @choices    = (distractors << player.team).shuffle
  end
end
