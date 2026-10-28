class UniformPiece < ApplicationRecord
  include SeedObservation
  belongs_to :uniform
  has_many :asset_representations, as: :subject, dependent: :destroy
  validates :name, presence: true, uniqueness: { scope: :uniform_id }
end
