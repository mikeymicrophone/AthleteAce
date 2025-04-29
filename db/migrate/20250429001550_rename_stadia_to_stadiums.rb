class RenameStadiaToStadiums < ActiveRecord::Migration[8.0]
  def change
    rename_table :stadia, :stadiums
  end
end
