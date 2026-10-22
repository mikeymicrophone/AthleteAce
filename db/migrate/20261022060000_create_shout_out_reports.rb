class CreateShoutOutReports < ActiveRecord::Migration[8.1]
  def change
    create_table :shout_out_reports do |t|
      t.references :shout_out, null: false, foreign_key: true
      t.references :reporter, foreign_key: { to_table: :aces, on_delete: :nullify }
      t.string :reason, null: false
      t.text :note
      t.string :resolution
      t.text :decision_reason
      t.references :resolved_by, foreign_key: { to_table: :aces, on_delete: :nullify }
      t.datetime :resolved_at
      t.timestamps
    end
    add_index :shout_out_reports, [ :shout_out_id, :reporter_id ], unique: true
    add_index :shout_out_reports, [ :resolved_at, :shout_out_id ]
    add_check_constraint :shout_out_reports, "reason IN ('Harassment', 'Spam', 'Off-topic', 'Other')", name: "report_reason"
    add_check_constraint :shout_out_reports, "(resolution IS NULL AND resolved_at IS NULL) OR (resolution IS NOT NULL AND resolution IN ('kept_live', 'hidden') AND resolved_at IS NOT NULL)", name: "report_resolution"
  end
end
