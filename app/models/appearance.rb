class Appearance < ApplicationRecord
  include SeedObservation
  include ParticipationValidation

  belongs_to :player
  belongs_to :contestant
  belongs_to :stint, optional: true
  has_one :contest, through: :contestant
  has_one :campaign, through: :contestant
  has_one :team, through: :campaign

  validates :player_id, uniqueness: { scope: :contestant_id }
  validate do
    errors.add :contestant, "must identify a game contest" if contestant && contestant.contest&.kind != "game"
    validate_player_sport(contestant&.campaign&.team)
    validate_linked_stint(contestant&.campaign&.team, contestant&.contest&.begin_date)
    errors.add :statistics, "must be a mapping" unless statistics.is_a?(Hash)
  end
end
