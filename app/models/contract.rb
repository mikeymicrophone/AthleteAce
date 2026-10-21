class Contract < ApplicationRecord
  belongs_to :player
  belongs_to :organization
  belongs_to :team, optional: true
  has_many :activations, dependent: :nullify
  has_many :campaigns, through: :activations
  has_many :stints, dependent: :nullify

  validates :end_date, comparison: { greater_than_or_equal_to: :start_date }, if: -> { start_date.present? && end_date.present? }
  validate :participation_players_match

  def duration
    return unless start_date && end_date

    (end_date - start_date).to_i
  end

  private

  def participation_players_match
    return unless persisted? && will_save_change_to_player_id?
    if activations.where.not(player_id: player_id).exists? || stints.where.not(player_id: player_id).exists?
      errors.add :player, "must match the linked participation records"
    end
  end
end
