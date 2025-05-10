class Quest < ApplicationRecord
  has_many :highlights, dependent: :destroy
  has_many :achievements, through: :highlights
  has_many :goals, dependent: :destroy
  has_many :aces, through: :goals
  
  validates :name, presence: true
  
  # Add an achievement to this quest
  def add_achievement(achievement, position: nil, required: true)
    highlights.create(
      achievement: achievement,
      position: position,
      required: required
    )
  end
  
  # Remove an achievement from this quest
  def remove_achievement(achievement)
    highlights.where(achievement: achievement).destroy_all
  end
  
  # Get required achievements for this quest
  def required_achievements
    achievements.merge(Highlight.required)
  end
  
  # Get optional achievements for this quest
  def optional_achievements
    achievements.merge(Highlight.optional)
  end
  
  # Get teams associated with this quest's achievements
  def associated_teams
    teams = []
    achievements.each do |achievement|
      case achievement.target
      when Team
        teams << achievement.target
      when League
        teams.concat(achievement.target.teams)
      when Division
        teams.concat(achievement.target.teams)
      when Conference
        teams.concat(achievement.target.divisions.flat_map(&:teams))
      # Add other target types if needed
      end
    end
    teams.uniq
  end
end
