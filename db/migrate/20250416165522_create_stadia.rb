class CreateStadia < ActiveRecord::Migration[8.0]
  def change
    create_table :stadia do |t|
      t.string :name
      t.references :city, null: false, foreign_key: true
      t.integer :capacity
      t.integer :opened_year
      t.string :url
      t.string :address

      t.timestamps
    end
  end
end
