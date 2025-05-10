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
    total_required = quest.highlights.required.count
    return 0 if total_required.zero?
    
    (progress.to_f / total_required * 100).round
  end
  
  # Get all the required achievements for this goal's quest
  def required_achievements
    quest.achievements.merge(Highlight.required)
  end
  
  # Get all the optional achievements for this goal's quest
  def optional_achievements
    quest.achievements.merge(Highlight.optional)
  end
  
  # Get all achievements (both required and optional) for this goal's quest
  def all_achievements
    quest.achievements
  end
  
  scope :active, -> { where.not(status: 'completed') }
end
