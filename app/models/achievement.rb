class Achievement < ApplicationRecord
  TARGET_TYPES = %w[Player Team Division Conference League Sport City State Country Federation].freeze

  has_many :highlights, dependent: :destroy
  has_many :quests, through: :highlights
  # Presence is checked below, after the type check, so a bogus type is never constantized
  belongs_to :target, polymorphic: true, optional: true

  validates :name, presence: true
  validates :target_type, inclusion: { in: TARGET_TYPES }
  validates :target, presence: { message: :required }, if: -> { TARGET_TYPES.include?(target_type) }
  
  # Add this achievement to a quest
  def add_to_quest(quest, position: nil, required: true)
    highlights.create(
      quest: quest,
      position: position,
      required: required
    )
  end
  
  # Remove this achievement from a quest
  def remove_from_quest(quest)
    highlights.where(quest: quest).destroy_all
  end
end
