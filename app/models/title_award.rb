class TitleAward < ApplicationRecord
  include SeedObservation
  belongs_to :contest
  belongs_to :winner, class_name: "Contestant"
  has_one :campaign, through: :winner
  has_one :team, through: :campaign

  validates :key, presence: true, length: { maximum: 80 }, format: { with: /\A[a-z0-9][a-z0-9_-]*\z/ }, uniqueness: { scope: :contest_id }
  validates :name, presence: true, length: { maximum: 200 }
  validate do
    errors.add :contest, "must be a competition, not a game" if contest&.kind == "game"
    errors.add :winner, "must be entered in this competition" if winner && winner.contest_id != contest_id
  end
end
