class Goal < ApplicationRecord
  belongs_to :ace
  belongs_to :quest
  
  validates :status, presence: true, inclusion: { in: %w[not_started in_progress completed] }
  validates :progress, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  
  # Default values
  after_initialize :set_defaults, if: :new_record?
  
  def set_defaults
    self.status ||= 'not_started'
    self.progress ||= 0
  end
  
  def percent_complete
    total_achievements = quest.achievements.count
    return 0 if total_achievements.zero?
    
    (progress.to_f / total_achievements * 100).round
  end
end
