class AddDetailsToQuests < ActiveRecord::Migration[8.0]
  def change
    add_column :quests, :details, :json
  end
end
