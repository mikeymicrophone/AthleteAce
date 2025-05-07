class RemoveQuestFromAchievements < ActiveRecord::Migration[8.0]
  def change
    remove_reference :achievements, :quest, null: false, foreign_key: true
  end
end
