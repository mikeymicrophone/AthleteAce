class Stint < ApplicationRecord
  include SeedObservation
  include ParticipationValidation

  belongs_to :player
  belongs_to :team
  belongs_to :contract, optional: true
  belongs_to :start_transaction, class_name: "Transaction", optional: true
  belongs_to :end_transaction, class_name: "Transaction", optional: true
  has_many :roster_entries, dependent: :nullify
  has_many :appearances, dependent: :nullify

  validates :end_date, comparison: { greater_than_or_equal_to: :start_date }, if: -> { start_date && end_date }
  validate :assignment_context_matches
  validate :preserve_linked_participation

  def permits_date?(date)
    date.nil? || ((!start_date || date >= start_date) && (!end_date || date <= end_date))
  end

  private

  def assignment_context_matches
    validate_player_sport(team)
    errors.add :contract, "must belong to the player" if contract && contract.player != player
  end

  def preserve_linked_participation
    return unless persisted? && (changes.keys & %w[player_id team_id start_date end_date]).any?
    (roster_entries.includes(roster: :campaign).to_a + appearances.includes(contestant: [ :contest, :campaign ]).to_a).each do |participation|
      participation.stint = self
      errors.add :base, "Change would invalidate participation: #{participation.errors.full_messages.join(', ')}" unless participation.valid?
    end
  end
end
