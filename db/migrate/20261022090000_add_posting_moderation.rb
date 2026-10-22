class AddPostingModeration < ActiveRecord::Migration[8.1]
  def change
    create_table :warnings do |t|
      t.references :ace, null: false, foreign_key: { on_delete: :cascade }
      t.references :moderator, foreign_key: { to_table: :aces, on_delete: :nullify }
      t.string :reason, null: false, limit: 2000
      t.references :subject, polymorphic: true
      t.string :subject_name
      t.string :request_key, null: false, limit: 128
      t.timestamps
    end
    add_index :warnings, [ :ace_id, :request_key ], unique: true

    create_table :mutes do |t|
      t.references :ace, null: false, foreign_key: { on_delete: :cascade }
      t.references :moderator, foreign_key: { to_table: :aces, on_delete: :nullify }
      t.string :reason, null: false, limit: 2000
      t.text :note
      t.integer :duration_hours, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.references :hidden_shout_out, foreign_key: { to_table: :shout_outs }
      t.string :request_key, null: false, limit: 128
      t.datetime :ended_at
      t.references :ended_by, foreign_key: { to_table: :aces, on_delete: :nullify }
      t.string :end_reason, limit: 2000
      t.timestamps
    end
    add_index :mutes, [ :ace_id, :request_key ], unique: true
    add_index :mutes, [ :ace_id, :ends_at ]
    add_check_constraint :mutes, "duration_hours IN (24, 168, 720) AND ends_at > starts_at", name: "valid_posting_mute_duration"

    create_table :moderator_notes do |t|
      t.references :ace, null: false, foreign_key: { on_delete: :cascade }
      t.references :moderator, foreign_key: { to_table: :aces, on_delete: :nullify }
      t.text :body, null: false
      t.string :request_key, null: false, limit: 128
      t.timestamps
    end
    add_index :moderator_notes, [ :ace_id, :request_key ], unique: true
  end
end
