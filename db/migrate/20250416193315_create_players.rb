class CreatePlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :players do |t|
      t.string :first_name
      t.string :last_name
      t.string :nicknames, array: true, default: []
      t.date :birthdate
      t.references :birth_city, null: true, foreign_key: { to_table: :cities }
      t.references :birth_country, null: true, foreign_key: { to_table: :countries }
      t.string :current_position
      t.integer :debut_year
      t.integer :draft_year
      t.boolean :active
      t.text :bio, array: true, default: []
      t.text :photo_urls, array: true, default: []
      t.references :team, null: true, foreign_key: true

      t.timestamps
    end
  end
end
