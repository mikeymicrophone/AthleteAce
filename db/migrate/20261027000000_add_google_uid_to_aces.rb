class AddGoogleUidToAces < ActiveRecord::Migration[8.1]
  def change
    add_column :aces, :google_uid, :string
    add_index :aces, :google_uid, unique: true, where: "google_uid IS NOT NULL"
  end
end
