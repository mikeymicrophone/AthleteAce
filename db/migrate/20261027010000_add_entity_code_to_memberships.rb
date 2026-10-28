class AddEntityCodeToMemberships < ActiveRecord::Migration[8.1]
  def change
    add_column :memberships, :entity_code, :string
    add_index :memberships, :entity_code, unique: true
  end
end
