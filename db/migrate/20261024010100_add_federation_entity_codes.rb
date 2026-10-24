class AddFederationEntityCodes < ActiveRecord::Migration[8.1]
  def change
    add_column :federations, :entity_code, :string
    add_index :federations, :entity_code, unique: true
  end
end
