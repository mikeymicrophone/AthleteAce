class CreateFederations < ActiveRecord::Migration[8.0]
  def change
    create_table :federations do |t|
      t.string :name
      t.string :abbreviation
      t.text :description
      t.string :url
      t.string :logo_url

      t.timestamps
    end
  end
end
