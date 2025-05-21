class CreateGameAttempts < ActiveRecord::Migration[8.0]
  def change
    create_table :game_attempts do |t|
      t.references :ace, null: false, foreign_key: true
      t.string :game_type, null: false
      t.references :subject_entity, polymorphic: true, null: false
      t.references :target_entity, polymorphic: true, null: false
      t.jsonb :options_presented, null: false, default: []
      t.references :chosen_entity, polymorphic: true, null: true # Can be null if no choice made
      t.boolean :is_correct, null: false
      t.integer :time_elapsed_ms, null: false

      t.timestamps
    end
  end
end
