class CreateTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :teams do |t|
      t.string :mascot
      t.string :territory
      t.references :league, null: false, foreign_key: true
      t.references :stadium, null: true, foreign_key: true
      t.integer :founded_year
      t.string :abbreviation
      t.string :url
      t.string :logo_url
      t.string :primary_color
      t.string :secondary_color
      t.string :coach_name

      t.timestamps
    end
  end
end
