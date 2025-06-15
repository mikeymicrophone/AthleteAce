class Contestant < ApplicationRecord
  belongs_to :contest
  belongs_to :campaign
  
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
end
