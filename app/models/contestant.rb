class Contestant < ApplicationRecord
  belongs_to :contest
  belongs_to :campaign
  has_many :appearances, dependent: :destroy
  validates :campaign_id, uniqueness: { scope: :contest_id }
  validate :preserve_appearance_context
  
  validates :placing, numericality: { greater_than: 0 }, allow_nil: true
  validates :wins, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :losses, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  
  scope :by_placing, -> { order(:placing) }
  scope :winners, -> { where(placing: 1) }
  scope :runner_ups, -> { where(placing: 2) }
  
  def winner?
    placing == 1
  end
  
  def runner_up?
    placing == 2
  end

  private

  def preserve_appearance_context
    return unless persisted? && (will_save_change_to_campaign_id? || will_save_change_to_contest_id?)
    appearances.includes(:player, :stint).each do |appearance|
      appearance.contestant = self
      errors.add :base, "Change would invalidate an appearance: #{appearance.errors.full_messages.join(', ')}" unless appearance.valid?
    end
  end
end
