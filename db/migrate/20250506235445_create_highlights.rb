class CreateHighlights < ActiveRecord::Migration[8.0]
  def change
    create_table :highlights do |t|
      t.references :quest, null: false, foreign_key: true
      t.references :achievement, null: false, foreign_key: true
      t.integer :position
      t.boolean :required, default: true

      t.timestamps
    end
    
    add_index :highlights, [:quest_id, :achievement_id], unique: true
  end
end
