class CreateContestants < ActiveRecord::Migration[8.0]
  def change
    create_table :contestants do |t|
      t.references :contest, null: false, foreign_key: true
      t.references :campaign, null: false, foreign_key: true
      t.integer :placing
      t.integer :wins
      t.integer :losses
      t.json :tiebreakers

      t.string :seed_version
      t.timestamp :last_seeded_at

      t.index [:contest_id, :campaign_id], unique: true

      t.timestamps
    end
  end
end
