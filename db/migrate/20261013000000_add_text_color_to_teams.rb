class AddTextColorToTeams < ActiveRecord::Migration[8.1]
  def change
    add_column :teams, :text_color, :string
  end
end
