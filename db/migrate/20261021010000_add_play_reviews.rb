class AddPlayReviews < ActiveRecord::Migration[8.1]
  def change
    add_column :aces, :time_zone, :string
    create_table :practice_reviews do |t|
      t.references :ace, null: false, foreign_key: true
      t.string :game_type, null: false
      t.string :subject_type, null: false
      t.bigint :subject_id, null: false
      t.string :target_type, null: false
      t.bigint :target_id, null: false
      t.jsonb :question, null: false
      t.integer :correct_streak, null: false, default: 0
      t.datetime :due_at, null: false
      t.references :last_attempt, null: false, foreign_key: { to_table: :game_attempts, on_delete: :cascade }
      t.timestamps
    end
    add_index :practice_reviews, [ :ace_id, :game_type, :subject_type, :subject_id, :target_type, :target_id ], unique: true, name: "index_practice_reviews_on_identity"
    add_index :practice_reviews, [ :ace_id, :due_at ]
  end
end
