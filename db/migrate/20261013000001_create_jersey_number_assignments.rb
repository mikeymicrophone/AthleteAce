class CreateJerseyNumberAssignments < ActiveRecord::Migration[8.1]
  def change
    enable_extension "btree_gist" unless extension_enabled?("btree_gist")

    create_table :jersey_number_assignments do |t|
      t.references :player, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.string :number, null: false
      t.date :start_date
      t.date :end_date
      t.jsonb :source, null: false, default: {}
      t.jsonb :details, null: false, default: {}
      t.string :entity_code
      t.timestamps
      t.index :entity_code, unique: true
    end
    add_check_constraint :jersey_number_assignments,
      "start_date IS NULL OR end_date IS NULL OR end_date >= start_date", name: "jersey_numbers_have_ordered_dates"
    add_check_constraint :jersey_number_assignments, "number ~ '^[0-9]{1,3}$'", name: "jersey_numbers_are_numeric_strings"
    add_exclusion_constraint :jersey_number_assignments,
      "player_id WITH =, team_id WITH =, daterange(start_date, end_date, '[]') WITH &&",
      using: :gist, name: "jersey_numbers_do_not_overlap"
  end
end
