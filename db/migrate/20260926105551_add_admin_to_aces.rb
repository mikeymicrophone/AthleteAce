class AddAdminToAces < ActiveRecord::Migration[8.0]
  def change
    add_column :aces, :admin, :boolean, default: false, null: false
  end
end
