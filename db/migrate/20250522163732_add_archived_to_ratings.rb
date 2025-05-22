class AddArchivedToRatings < ActiveRecord::Migration[7.0]
  def change
    add_column :ratings, :archived, :boolean, null: false, default: false
    add_index :ratings, :archived
  end
end
