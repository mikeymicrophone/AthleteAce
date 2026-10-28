class PlayerGroup < ApplicationRecord
  include SeedObservation

  has_many :player_group_memberships, dependent: :destroy
  has_many :players, through: :player_group_memberships

  validates :name, presence: true
end
