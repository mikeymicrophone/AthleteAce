class CreateContests < ActiveRecord::Migration[8.0]
  def change
    create_table :contests do |t|
      t.string :name
      t.text :description
      t.references :context, polymorphic: true, null: false
      t.text :contestant_ids
      t.date :begin_date
      t.date :end_date
      t.integer :champion_id
      t.text :comments
      t.json :details
      t.string :seed_version
      t.timestamp :last_seeded_at

      t.timestamps
    end
  end
end
