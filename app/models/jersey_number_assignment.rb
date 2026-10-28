class JerseyNumberAssignment < ApplicationRecord
  belongs_to :player
  belongs_to :team

  before_validation { self.number = number&.strip }
  validates :number, presence: true, format: { with: /\A[0-9]{1,3}\z/ }
  validates :end_date, comparison: { greater_than_or_equal_to: :start_date }, if: -> { start_date && end_date }
  validate :matching_sport
  validate :nonoverlapping_period
  validate :metadata_is_mapping

  # Bounds are inclusive. Missing bounds deliberately mean an open-ended
  # assignment; an isolated roster observation does not assert such a period.
  scope :overlapping, ->(from, through) {
    where("(end_date IS NULL OR end_date >= ?) AND (start_date IS NULL OR start_date <= ?)", from, through)
  }

  def covers?(from, through)
    (!start_date || start_date <= from) && (!end_date || end_date >= through)
  end

  def self.valid_number?(value)
    value.is_a?(String) && value.match?(/\A[0-9]{1,3}\z/)
  end

  private

  def matching_sport
    if player&.sport && team&.sport && player.sport.id != team.sport.id
      errors.add :player, "must belong to the team's sport"
    end
  end

  def nonoverlapping_period
    return unless player_id && team_id
    return if start_date && end_date && end_date < start_date

    others = self.class.where(player_id: player_id, team_id: team_id).where.not(id: id)
    others = others.where("end_date IS NULL OR end_date >= ?", start_date) if start_date
    others = others.where("start_date IS NULL OR start_date <= ?", end_date) if end_date
    errors.add :base, "Number assignments for this player and team cannot overlap" if others.exists?
  end

  def metadata_is_mapping
    %i[source details].each do |field|
      errors.add field, "must be a mapping" unless public_send(field).is_a?(Hash)
    end
  end
end
