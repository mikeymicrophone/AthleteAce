class AddImageUrlsToModels < ActiveRecord::Migration[8.0]
  def change
    add_column :sports, :icon_url, :string
    add_column :countries, :flag_url, :string
    add_column :states, :flag_url, :string
    add_column :stadiums, :logo_url, :string
  end
end
