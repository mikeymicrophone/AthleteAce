class ContestGame < ApplicationRecord
  belongs_to :contest
  belongs_to :game

  validates :game_id, uniqueness: { scope: :contest_id }
  validate :competition_and_metadata_are_valid

  private

  def competition_and_metadata_are_valid
    errors.add :contest, "must be a competition, not a game" if contest&.kind == "game"
    unless metadata.is_a?(Hash)
      errors.add :metadata, "must be a mapping"
      return
    end
    round = metadata["round"]
    if metadata.key?("round") && (!round.is_a?(String) || !round.match?(/\A[a-z0-9][a-z0-9_-]{0,79}\z/))
      errors.add :metadata, "round must be a stable round key"
    elsif round && contest&.format_rules.is_a?(Hash) && contest.format_rules.key?("rounds")
      rounds = contest.format_rules["rounds"]
      unless rounds.is_a?(Array) && rounds.any? { |definition| definition.is_a?(Hash) && definition["key"] == round }
        errors.add :metadata, "round must be declared in the competition format"
      end
    end
    %w[game_number leg].each do |key|
      value = metadata[key]
      errors.add :metadata, "#{key} must be a positive integer" if metadata.key?(key) && !(value.is_a?(Integer) && value.positive?)
    end
    %w[group series].each do |key|
      value = metadata[key]
      errors.add :metadata, "#{key} must be text of at most 100 characters" if metadata.key?(key) && !(value.is_a?(String) && value.length <= 100)
    end
    return unless contest && game

    missing = game.contestants.where.not(campaign_id: contest.contestants.select(:campaign_id))
    errors.add :game, "participants must be entered in the competition" if missing.exists?
  end
end
