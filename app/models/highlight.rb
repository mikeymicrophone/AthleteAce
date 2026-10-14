class Highlight < ApplicationRecord
  include Moderatable
  belongs_to :quest
  belongs_to :achievement
  validate :visible_submission_parents
  
  validates :quest_id, uniqueness: { scope: :achievement_id }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  
  # Default values
  after_initialize :set_defaults, if: :new_record?
  
  def set_defaults
    self.required = true if self.required.nil?
  end
  
  # Scopes
  scope :public_requirements, -> { approved.where(achievement: Achievement.approved) }
  scope :required, -> { where(required: true) }
  scope :optional, -> { where(required: false) }
  scope :ordered, -> { order(position: :asc) }

  private

  def visible_submission_parents
    return unless created_by && (new_record? || will_save_change_to_quest_id? || will_save_change_to_achievement_id?)
    errors.add :quest, "is unavailable" unless Quest.visible_to(created_by).exists?(id: quest_id)
    errors.add :achievement, "is unavailable" unless Achievement.visible_to(created_by).exists?(id: achievement_id)
  end
end
