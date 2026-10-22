class CreateShoutOutReactions < ActiveRecord::Migration[8.1]
  def change
    create_table :shout_out_reactions do |t|
      t.references :shout_out, null: false, foreign_key: true
      t.references :ace, null: false, foreign_key: { on_delete: :cascade }
      t.string :kind, null: false
      t.timestamps
    end
    add_index :shout_out_reactions, [ :shout_out_id, :ace_id, :kind ], unique: true
    add_check_constraint :shout_out_reactions, "kind IN ('fire', 'love', 'legend')", name: "supported_shout_out_reaction"
  end
end
