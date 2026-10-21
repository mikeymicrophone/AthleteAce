class Roster < ApplicationRecord
  include SeedObservation

  belongs_to :campaign
  has_many :roster_entries, dependent: :destroy
  has_many :players, through: :roster_entries
  has_one :team, through: :campaign

  validates :kind, presence: true
  validates :coverage, inclusion: { in: %w[unknown partial complete] }
  validate :preserve_entry_context

  private

  def preserve_entry_context
    return unless persisted? && (will_save_change_to_campaign_id? || will_save_change_to_effective_on?)
    roster_entries.includes(:player, :stint).each do |entry|
      entry.roster = self
      errors.add :base, "Change would invalidate a roster entry: #{entry.errors.full_messages.join(', ')}" unless entry.valid?
    end
  end
end
