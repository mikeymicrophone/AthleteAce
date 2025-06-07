class Goal < ApplicationRecord
  belongs_to :ace
  belongs_to :quest
  
  validates :status, presence: true, inclusion: { in: %w[not_started in_progress completed] }
  validates :progress, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  
  after_initialize :set_defaults, if: :new_record?
  
  def set_defaults
    self.status ||= 'not_started'
    self.progress ||= 0
  end
  
  def percent_complete
    total_required = quest.highlights.required.count
    return 0 if total_required.zero?
    
    (progress.to_f / total_required * 100).round
  end
  
  def required_achievements
    quest.achievements.merge Highlight.required
  end
  
  def optional_achievements
    quest.achievements.merge Highlight.optional
  end
  
  def all_achievements
    quest.achievements
  end
  
  scope :active, -> { where.not(status: 'completed') }
end
