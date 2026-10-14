class LockModeratedContentVersions < ActiveRecord::Migration[8.1]
  def change
    %i[quests achievements highlights spectrums].each do |table|
      add_column table, :lock_version, :integer, null: false, default: 0
    end
  end
end
