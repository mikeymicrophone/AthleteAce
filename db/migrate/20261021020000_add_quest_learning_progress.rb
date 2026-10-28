class AddQuestLearningProgress < ActiveRecord::Migration[8.1]
  def change
    add_column :game_rounds, :newly_known_player_ids, :jsonb, default: [], null: false
    create_table :goal_achievements do |t|
      t.references :goal, null: false, foreign_key: true
      t.references :achievement, null: false, foreign_key: true
      t.jsonb :player_ids, default: [], null: false
      t.jsonb :required_player_ids, default: [], null: false
      t.jsonb :practice_scope, default: {}, null: false
      t.datetime :completed_at
      t.timestamps
    end
    add_index :goal_achievements, [ :goal_id, :achievement_id ], unique: true
  end
end
