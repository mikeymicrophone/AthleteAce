class CreateGameRounds < ActiveRecord::Migration[8.1]
  def change
    create_table :game_rounds do |t|
      t.references :ace, null: false, foreign_key: true
      t.string :game_type, null: false
      t.integer :length, null: false
      t.jsonb :scope, null: false, default: {}
      t.string :scope_label, null: false
      t.jsonb :questions, null: false, default: []
      t.integer :position, null: false, default: 0
      t.datetime :started_at, null: false
      t.datetime :finished_at
      t.datetime :paused_at
      t.datetime :question_started_at
      t.integer :question_elapsed_ms, null: false, default: 0
      t.timestamps
    end
    add_reference :game_attempts, :game_round, foreign_key: true
    add_column :game_attempts, :round_position, :integer
    add_index :game_attempts, [:game_round_id, :round_position], unique: true
    add_check_constraint :game_rounds, "length BETWEEN 1 AND 30 AND position BETWEEN 0 AND length", name: "game_round_progress"
    add_check_constraint :game_attempts, "(game_round_id IS NULL AND round_position IS NULL) OR (game_round_id IS NOT NULL AND round_position >= 0)", name: "game_attempt_round_position"
  end
end
