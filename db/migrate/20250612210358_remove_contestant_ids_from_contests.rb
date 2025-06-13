class RemoveContestantIdsFromContests < ActiveRecord::Migration[8.0]
  def change
    remove_column :contests, :contestant_ids, :text
  end
end
