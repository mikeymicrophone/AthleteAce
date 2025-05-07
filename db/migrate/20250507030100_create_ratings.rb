class CreateRatings < ActiveRecord::Migration[8.0]
  def change
    create_table :ratings do |t|
      t.references :ace, null: false, foreign_key: true
      t.references :spectrum, null: false, foreign_key: true
      t.references :target, polymorphic: true, null: false
      t.integer :value, null: false, limit: 8  # Using bigint for the large range (-10,000 to 10,000)
      t.text :notes

      t.timestamps
    end
    
    # Add a unique index to prevent duplicate ratings by the same ace for the same target on the same spectrum
    add_index :ratings, [:ace_id, :spectrum_id, :target_type, :target_id], unique: true, name: 'index_ratings_on_ace_spectrum_and_target'
  end
end
