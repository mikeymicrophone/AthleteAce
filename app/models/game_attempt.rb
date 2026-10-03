class GameAttempt < ApplicationRecord
  # game_type => [subject type, answer type]
  GAME_TYPES = {
    "player_team_match" => ["Player", "Team"],
    "guess_the_division" => ["Team", "Division"]
  }.freeze

  belongs_to :ace
  belongs_to :game_round, optional: true
  # Presence is checked below, after the type checks, so a bogus type is never constantized
  belongs_to :subject_entity, polymorphic: true, optional: true
  belongs_to :target_entity, polymorphic: true, optional: true
  belongs_to :chosen_entity, polymorphic: true, optional: true

  validates :game_type, inclusion: { in: GAME_TYPES.keys }
  validate :round_matches_attempt
  validate :entity_types_match_game
  validates :subject_entity, :target_entity, presence: { message: :required }, if: :entity_types_valid?

  def correct?
    is_correct
  end

  def chose_target?
    chosen_entity_id.present? && chosen_entity_type == target_entity_type && chosen_entity_id == target_entity_id
  end

  # The right answer for this attempt's subject, e.g. a player's team
  def expected_target_entity
    return unless entity_types_valid? && subject_entity

    case game_type
    when "player_team_match" then subject_entity.team
    when "guess_the_division" then subject_entity.division
    end
  end

  private

  def round_matches_attempt
    return unless game_round

    errors.add(:game_round, "does not match the ace or game") unless game_round.ace_id == ace_id && game_round.game_type == game_type
    errors.add(:round_position, "is outside the round") unless round_position && (0...game_round.length).cover?(round_position)
  end

  def entity_types_valid?
    subject_type, answer_type = GAME_TYPES[game_type]
    subject_type.present? &&
      subject_entity_type == subject_type &&
      target_entity_type == answer_type &&
      (chosen_entity_type.nil? || chosen_entity_type == answer_type)
  end

  def entity_types_match_game
    return if game_type.blank? || !GAME_TYPES.key?(game_type) || entity_types_valid?

    errors.add(:base, "Entity types don't match the #{game_type} game")
  end
end
