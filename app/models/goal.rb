class Goal < ApplicationRecord
  belongs_to :ace
  belongs_to :quest
  
  validates :status, presence: true, inclusion: { in: %w[not_started in_progress completed] }
  validates :progress, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate(on: :create) { errors.add(:quest, "must be approved") if quest && !quest.approved? }
  
  after_initialize :set_defaults, if: :new_record?
  
  def set_defaults
    self.status ||= 'not_started'
    self.progress ||= 0
  end
  
  def percent_complete
    total_required = quest.highlights.public_requirements.required.count
    return 0 if total_required.zero?
    
    (progress.to_f / total_required * 100).round
  end
  
  def required_achievements
    quest.required_achievements
  end
  
  def optional_achievements
    quest.optional_achievements
  end
  
  def all_achievements
    quest.achievements.approved.merge(Highlight.approved)
  end
  
  scope :active, -> { where.not(status: 'completed') }
end
