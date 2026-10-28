class RosterEntry < ApplicationRecord
  include SeedObservation
  include ParticipationValidation

  belongs_to :roster
  belongs_to :player
  belongs_to :stint, optional: true

  validates :player_id, uniqueness: { scope: :roster_id }
  validate do
    validate_player_sport(roster&.campaign&.team)
    validate_linked_stint(roster&.campaign&.team, roster&.effective_on)
  end
end
