class AddCompetitionGamesAndTitles < ActiveRecord::Migration[8.1]
  def up
    add_column :contests, :type, :string
    add_column :contests, :format_rules, :jsonb, null: false, default: {}
    change_column :contests, :details, :jsonb, using: "details::jsonb"
    execute "UPDATE contests SET type = 'Game' WHERE kind = 'game'"
    add_check_constraint :contests, "(type IS NOT NULL AND kind IS NOT NULL AND type = 'Game' AND kind = 'game') OR (type IS NULL AND kind IS DISTINCT FROM 'game')", name: "contest_game_type"
    add_check_constraint :contests, "jsonb_typeof(format_rules) = 'object'", name: "contest_format_is_object"
    add_index :contests, :type

    create_table :contest_games do |t|
      t.references :contest, null: false, foreign_key: true
      t.references :game, null: false, foreign_key: { to_table: :contests }
      t.jsonb :metadata, null: false, default: {}
      t.string :entity_code
      t.timestamps
    end
    add_index :contest_games, [ :contest_id, :game_id ], unique: true
    add_index :contest_games, :entity_code, unique: true
    add_index :contest_games, :metadata, using: :gin
    add_check_constraint :contest_games, "contest_id <> game_id", name: "game_cannot_contain_itself"
    add_check_constraint :contest_games, "jsonb_typeof(metadata) = 'object'", name: "contest_game_metadata_is_object"

    create_table :title_awards do |t|
      t.references :contest, null: false, foreign_key: true
      t.bigint :winner_id, null: false
      t.string :key, null: false
      t.string :name, null: false
      t.date :awarded_on
      t.jsonb :source, null: false, default: {}
      t.jsonb :details, null: false, default: {}
      t.string :entity_code
      t.timestamps
    end
    add_index :title_awards, [ :contest_id, :key ], unique: true
    add_index :title_awards, :entity_code, unique: true
    add_index :contestants, [ :contest_id, :id ], unique: true
    add_foreign_key :title_awards, :contestants, column: [ :contest_id, :winner_id ], primary_key: [ :contest_id, :id ]
  end

  def down
    drop_table :title_awards
    remove_index :contestants, [ :contest_id, :id ]
    drop_table :contest_games
    remove_check_constraint :contests, name: "contest_game_type"
    remove_check_constraint :contests, name: "contest_format_is_object"
    remove_index :contests, :type
    remove_column :contests, :type
    remove_column :contests, :format_rules
    change_column :contests, :details, :json, using: "details::json"
  end
end
