class Person < ApplicationRecord
  include SeedObservation

  belongs_to :player, optional: true
  has_many :staff_tenures, dependent: :restrict_with_error

  validates :name, :entity_code, presence: true
  validates :entity_code, uniqueness: true
  validates :player_id, uniqueness: true, allow_nil: true
end
