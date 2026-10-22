class PlayerGroupMembership < ApplicationRecord
  include SeedObservation

  belongs_to :player_group
  belongs_to :player

  validates :player_id, uniqueness: { scope: :player_group_id }
end
