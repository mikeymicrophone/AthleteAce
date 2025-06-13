class AddDetailsToAchievements < ActiveRecord::Migration[8.0]
  def change
    add_column :achievements, :details, :json
  end
end
