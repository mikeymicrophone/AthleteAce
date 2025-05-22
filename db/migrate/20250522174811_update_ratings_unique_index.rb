class UpdateRatingsUniqueIndex < ActiveRecord::Migration[7.0]
  def change
    # Remove the existing unique index
    remove_index :ratings, name: "index_ratings_on_ace_spectrum_and_target"
    
    # Add a partial unique index that only applies to non-archived ratings
    add_index :ratings, [:ace_id, :spectrum_id, :target_type, :target_id], 
              name: "index_ratings_on_ace_spectrum_and_target_active", 
              unique: true,
              where: "archived = FALSE"
  end
end
