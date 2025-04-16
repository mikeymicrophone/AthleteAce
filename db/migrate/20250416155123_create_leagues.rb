class CreateLeagues < ActiveRecord::Migration[8.0]
  def change
    create_table :leagues do |t|
      t.string :name
      t.string :url
      t.string :ios_app_url
      t.integer :year_of_origin
      t.string :official_rules_url
      t.references :sport, null: false, foreign_key: true

      t.timestamps
    end
  end
end
