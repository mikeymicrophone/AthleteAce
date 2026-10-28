class CreateShoutOutDrafts < ActiveRecord::Migration[8.1]
  def change
    create_table :shout_out_drafts do |t|
      t.references :ace, null: false, foreign_key: true
      t.references :target, polymorphic: true
      t.text :message, null: false
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_check_constraint :shout_out_drafts, "target_type IS NULL OR target_type IN ('Team', 'Player')", name: "drafts_supported_target"
  end
end
