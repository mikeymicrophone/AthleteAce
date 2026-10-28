class AddPlayerGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :player_groups do |t|
      t.string :name, null: false
      t.text :description
      t.string :entity_code
      t.jsonb :source, default: {}, null: false
      t.jsonb :details, default: {}, null: false
      t.timestamps
    end
    add_index :player_groups, :entity_code, unique: true

    create_table :player_group_memberships do |t|
      t.references :player_group, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.string :entity_code
      t.jsonb :source, default: {}, null: false
      t.jsonb :details, default: {}, null: false
      t.timestamps
    end
    add_index :player_group_memberships, [ :player_group_id, :player_id ], unique: true
    add_index :player_group_memberships, :entity_code, unique: true
  end
end
