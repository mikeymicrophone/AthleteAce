class IndexModerationDecisionHistory < ActiveRecord::Migration[8.1]
  def change
    add_index :moderation_decisions, [ :created_at, :id ]
  end
end
