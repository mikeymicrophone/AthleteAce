class CreateActivations < ActiveRecord::Migration[8.0]
  def change
    create_table :activations do |t|
      t.references :contract, null: false, foreign_key: true
      t.references :campaign, null: false, foreign_key: true
      t.date :start_date
      t.date :end_date
      t.json :details
      t.string :seed_version
      t.timestamp :last_seeded_at

      t.timestamps
    end
  end
end
