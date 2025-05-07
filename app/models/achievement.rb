class Achievement < ApplicationRecord
  has_many :highlights, dependent: :destroy
  has_many :quests, through: :highlights
  belongs_to :target, polymorphic: true
  
  validates :name, presence: true
  
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
