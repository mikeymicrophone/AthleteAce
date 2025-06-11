class CreateCampaigns < ActiveRecord::Migration[8.0]
  def change
    create_table :campaigns do |t|
      t.references :team, null: false, foreign_key: true
      t.references :season, null: false, foreign_key: true
      t.text :comments, array: true, default: [], comment: "Array of comments about the campaign"
      t.string :seed_version, comment: "Version when this record was seeded"
      t.datetime :last_seeded_at, comment: "When this record was last seeded"
      
      t.timestamps
    end
    
    add_index :campaigns, [:team_id, :season_id], unique: true
  end
end
