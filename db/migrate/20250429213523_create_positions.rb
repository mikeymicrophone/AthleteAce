class CreatePositions < ActiveRecord::Migration[8.0]
  def change
    create_table :positions do |t|
      t.string :name, null: false
      t.string :abbreviation
      t.text :description
      t.references :sport, null: false, foreign_key: true

      t.timestamps
    end
    
    # Add a unique index for position name scoped to sport
    add_index :positions, [:name, :sport_id], unique: true
  end
end
