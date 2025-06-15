class CreateContracts < ActiveRecord::Migration[8.0]
  def change
    create_table :contracts do |t|
      t.references :player, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.date :start_date
      t.date :end_date
      t.decimal :total_dollar_value
      t.json :details
      t.string :seed_version
      t.timestamp :last_seeded_at

      t.timestamps
    end
  end
end
