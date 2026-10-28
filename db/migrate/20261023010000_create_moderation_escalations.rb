class CreateModerationEscalations < ActiveRecord::Migration[8.1]
  def change
    create_table :moderation_escalations do |t|
      t.references :subject, polymorphic: true, null: false
      t.references :subject_ace, foreign_key: { to_table: :aces, on_delete: :nullify }
      t.references :requested_by, foreign_key: { to_table: :aces, on_delete: :nullify }
      t.string :subject_name, null: false
      t.text :reason, null: false
      t.jsonb :snapshot, null: false, default: {}
      t.integer :revision
      t.string :captured_status
      t.string :request_key, null: false, limit: 128
      t.string :resolution
      t.text :resolution_reason
      t.references :resolved_by, foreign_key: { to_table: :aces, on_delete: :nullify }
      t.datetime :resolved_at
      t.integer :lock_version, default: 0, null: false
      t.timestamps
    end
    add_index :moderation_escalations, [ :subject_type, :subject_id ], unique: true,
      where: "resolved_at IS NULL", name: "one_open_escalation_per_subject"
    add_index :moderation_escalations, [ :requested_by_id, :request_key ], unique: true,
      name: "unique_escalation_request"
    add_index :moderation_escalations, [ :resolved_at, :created_at, :id ]
  end
end
