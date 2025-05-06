class CreateGoals < ActiveRecord::Migration[8.0]
  def change
    create_table :goals do |t|
      t.references :ace, null: false, foreign_key: true
      t.references :quest, null: false, foreign_key: true
      t.string :status
      t.integer :progress

      t.timestamps
    end
  end
end
