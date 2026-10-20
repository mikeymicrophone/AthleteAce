class AddThemeToAces < ActiveRecord::Migration[8.1]
  def change
    add_column :aces, :theme, :string, default: "system", null: false
    add_check_constraint :aces, "theme IN ('light', 'dark', 'system')", name: "aces_theme"
  end
end
