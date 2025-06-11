class CreateSeasons < ActiveRecord::Migration[8.0]
  def change
    create_table :seasons do |t|
      t.references :year, null: false, foreign_key: true, comment: "Year when the season began"
      t.references :league, null: false, foreign_key: true, comment: "League the season belongs to"
      t.date :start_date, comment: "When the regular season started"
      t.date :end_date, comment: "When the regular season ended"
      t.date :playoff_start_date, comment: "When the playoffs started"
      t.date :playoff_end_date, comment: "When the playoffs ended"
      t.text :comments, array: true, default: [], comment: "Array of comments about the season"
      t.string :seed_version, comment: "Version when this record was seeded"
      t.datetime :last_seeded_at, comment: "When this record was last seeded"

      t.timestamps
    end
    
    add_index :seasons, [:year_id, :league_id], unique: true, name: "index_seasons_on_year_and_league"
    add_index :seasons, :seed_version
    add_index :seasons, :start_date
  end
end
