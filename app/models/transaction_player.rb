class TransactionPlayer < ApplicationRecord
  # "transaction" is an Active Record method; use event for the association.
  belongs_to :event, class_name: "Transaction", foreign_key: :transaction_id, inverse_of: :transaction_players
  belongs_to :player
  belongs_to :from_organization, class_name: "Organization", optional: true
  belongs_to :to_organization, class_name: "Organization", optional: true
  belongs_to :from_team, class_name: "Team", optional: true
  belongs_to :to_team, class_name: "Team", optional: true

  validates :player_id, uniqueness: { scope: :transaction_id }
  validate do
    errors.add :details, "must be a mapping" unless details.is_a?(Hash)
  end
end
