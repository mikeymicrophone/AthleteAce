class CreateRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :roles do |t|
      t.references :player, null: false, foreign_key: true
      t.references :position, null: false, foreign_key: true
      t.boolean :primary, default: false, null: false

      t.timestamps
    end
    
    # Add a unique index to prevent duplicate positions for a player
    add_index :roles, [:player_id, :position_id], unique: true
    
    # Add an index for finding primary positions quickly
    add_index :roles, [:player_id, :primary]
  end
end
