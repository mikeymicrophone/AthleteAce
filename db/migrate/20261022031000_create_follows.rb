class CreateFollows < ActiveRecord::Migration[8.1]
  def change
    create_table :follows do |t|
      t.references :ace, null: false, foreign_key: true
      t.references :followable, polymorphic: true, null: false
      t.timestamps
    end
    add_index :follows, [ :ace_id, :followable_type, :followable_id ], unique: true
    add_check_constraint :follows, "followable_type IN ('Team', 'Player')", name: "follows_supported_type"
  end
end
