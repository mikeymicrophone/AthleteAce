class AddContentModeration < ActiveRecord::Migration[8.1]
  def change
    add_column :aces, :moderator, :boolean, null: false, default: false
    %i[quests achievements highlights spectrums].each do |table|
      add_column table, :moderation_status, :string, null: false, default: "approved"
      add_column table, :moderation_revision, :integer, null: false, default: 1
      add_reference table, :created_by, foreign_key: { to_table: :aces, on_delete: :nullify }
      add_index table, [ :moderation_status, :created_at ]
      add_check_constraint table, "moderation_status IN ('pending', 'approved', 'rejected', 'hidden')", name: "#{table}_moderation_status"
    end
    create_table :moderation_decisions do |t|
      t.references :subject, polymorphic: true, null: false
      t.references :actor, foreign_key: { to_table: :aces, on_delete: :nullify }
      t.string :action, null: false
      t.string :from_status
      t.string :to_status, null: false
      t.integer :revision, null: false
      t.text :reason
      t.jsonb :snapshot, null: false, default: {}
      t.datetime :created_at, null: false
    end
    create_table :decision_evaluations do |t|
      t.references :subject, polymorphic: true
      t.integer :revision
      t.string :comparison_key, null: false
      t.string :provider, null: false
      t.string :model, null: false
      t.string :purpose, null: false
      t.string :policy_version, null: false
      t.string :status, null: false, default: "queued"
      t.string :choice
      t.string :error_code
      t.jsonb :request_snapshot, null: false, default: {}
      t.jsonb :answer, null: false, default: {}
      t.bigint :input_tokens
      t.decimal :input_usd_per_million, precision: 12, scale: 6, null: false
      t.decimal :estimated_usd, precision: 20, scale: 10
      t.integer :latency_ms
      t.timestamps
      t.index [ :comparison_key, :provider ], unique: true
    end
  end
end
