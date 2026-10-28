class CreateCatalogEdits < ActiveRecord::Migration[8.1]
  def change
    create_table :catalog_edits do |t|
      t.references :actor, foreign_key: { to_table: :aces, on_delete: :nullify }
      t.string :actor_name, null: false
      t.string :record_type, null: false
      t.bigint :record_id, null: false
      t.string :entity_code
      t.string :record_name, null: false
      t.jsonb :before_values, null: false
      t.jsonb :after_values, null: false
      t.jsonb :submitted_values, null: false
      t.string :request_key, null: false, limit: 128
      t.text :reason
      t.datetime :reason_supplied_at
      t.datetime :created_at, null: false
    end
    add_index :catalog_edits, [ :actor_id, :request_key ], unique: true
    add_index :catalog_edits, [ :record_type, :record_id, :id ]
    add_index :catalog_edits, :id, where: "reason IS NULL", name: "index_catalog_edits_without_reason"
    add_check_constraint :catalog_edits, "record_type IN ('Player', 'Team')", name: "catalog_edit_record_type"
    add_check_constraint :catalog_edits, "(reason IS NULL AND reason_supplied_at IS NULL) OR (reason IS NOT NULL AND length(btrim(reason)) BETWEEN 1 AND 2000 AND reason_supplied_at IS NOT NULL)", name: "catalog_edit_reason"
  end
end
