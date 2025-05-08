class CreateConferencesAndDivisions < ActiveRecord::Migration[7.0]
  def change
    create_table :conferences do |t|
      t.string :name
      t.string :abbreviation
      t.string :logo_url
      t.references :league, null: false, foreign_key: true

      t.timestamps
    end

    create_table :divisions do |t|
      t.string :name
      t.string :abbreviation
      t.string :logo_url
      t.references :conference, null: false, foreign_key: true

      t.timestamps
    end

    create_table :memberships do |t|
      t.references :team, null: false, foreign_key: true
      t.references :division, null: false, foreign_key: true
      t.date :start_date
      t.date :end_date
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
