class AddPeopleAndStaffTenures < ActiveRecord::Migration[8.1]
  def up
    create_table :people do |t|
      t.string :name, null: false
      t.references :player, foreign_key: { on_delete: :nullify }, index: { unique: true }
      t.string :entity_code, null: false
      t.jsonb :source, default: {}, null: false
      t.jsonb :details, default: {}, null: false
      t.timestamps
    end
    add_index :people, :entity_code, unique: true

    player_rows = Class.new(ActiveRecord::Base) { self.table_name = "players" }
    people = Class.new(ActiveRecord::Base) { self.table_name = "people" }
    player_rows.find_each do |player|
      code = player.entity_code.presence || SecureRandom.uuid.upcase
      people.create! player_id: player.id,
        name: [ player.first_name, player.last_name ].compact.join(" ").strip.presence || "Unnamed athlete",
        entity_code: "PERSON-#{code}"
    end

    create_table :staff_tenures do |t|
      t.references :person, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.references :team, foreign_key: true
      t.string :role, null: false
      t.string :title, null: false
      t.string :start_date
      t.string :end_date
      t.boolean :ongoing, default: false, null: false
      t.string :entity_code, null: false
      t.jsonb :source, default: {}, null: false
      t.jsonb :details, default: {}, null: false
      t.timestamps
    end
    add_index :staff_tenures, :entity_code, unique: true
    add_check_constraint :staff_tenures, "role IN ('coach', 'staff', 'broadcaster')", name: "staff_tenures_role"
    add_check_constraint :staff_tenures, "NOT ongoing OR end_date IS NULL", name: "staff_tenures_ongoing_end"
  end

  def down
    drop_table :staff_tenures
    drop_table :people
  end
end
