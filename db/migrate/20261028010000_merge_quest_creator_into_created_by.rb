# main recorded quest creators in creator_id while this branch used the
# moderation column created_by_id. Keep created_by_id and carry over any
# creator recorded only in creator_id.
class MergeQuestCreatorIntoCreatedBy < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE quests SET created_by_id = creator_id
      WHERE created_by_id IS NULL AND creator_id IS NOT NULL
    SQL
    remove_reference :quests, :creator, foreign_key: { to_table: :aces }, index: true
  end

  def down
    add_reference :quests, :creator, foreign_key: { to_table: :aces, on_delete: :nullify }
    execute "UPDATE quests SET creator_id = created_by_id"
  end
end
