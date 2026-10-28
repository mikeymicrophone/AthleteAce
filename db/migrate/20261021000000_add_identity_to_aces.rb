class AddIdentityToAces < ActiveRecord::Migration[8.1]
  def change
    add_column :aces, :username, :string
    add_column :aces, :display_name, :string
    add_column :aces, :avatar_color, :string, default: "#7A4B2A", null: false
    add_index :aces, "lower(username)", unique: true, name: "index_aces_on_lower_username"
  end
end
