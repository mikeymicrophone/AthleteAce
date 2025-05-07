class Highlight < ApplicationRecord
  belongs_to :quest
  belongs_to :achievement
  
  validates :quest_id, uniqueness: { scope: :achievement_id }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  
  # Default values
  after_initialize :set_defaults, if: :new_record?
  
  def set_defaults
    self.required = true if self.required.nil?
  end
  
  # Scopes
  scope :required, -> { where(required: true) }
  scope :optional, -> { where(required: false) }
  scope :ordered, -> { order(position: :asc) }
end
