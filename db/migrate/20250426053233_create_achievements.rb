class CreateAchievements < ActiveRecord::Migration[8.0]
  def change
    create_table :achievements do |t|
      t.string :name
      t.text :description
      t.references :quest, null: false, foreign_key: true
      t.references :target, polymorphic: true, null: false

      t.timestamps
    end
  end
end
