class Transaction < ApplicationRecord
  include SeedObservation

  has_many :transaction_players, foreign_key: :transaction_id, inverse_of: :event, dependent: :destroy
  has_many :players, through: :transaction_players
  has_many :starting_stints, class_name: "Stint", foreign_key: :start_transaction_id, dependent: :nullify
  has_many :ending_stints, class_name: "Stint", foreign_key: :end_transaction_id, dependent: :nullify

  validates :kind, presence: true
end
