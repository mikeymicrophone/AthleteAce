class GoalAchievement < ApplicationRecord
  belongs_to :goal
  belongs_to :achievement

  def progress
    (player_ids & required_player_ids).size
  end
end
