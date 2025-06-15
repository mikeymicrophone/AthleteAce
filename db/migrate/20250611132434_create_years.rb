class CreateYears < ActiveRecord::Migration[8.0]
  def change
    create_table :years do |t|
      t.integer :number, null: false, comment: "The year number (e.g., 2024)"
      t.string :seed_version, comment: "Version of the seed file that created or last updated this record"
      t.datetime :last_seeded_at, comment: "When this record was last updated by a seed"

      t.timestamps
    end
    
    add_index :years, :number, unique: true
    add_index :years, :seed_version
  end
end
