class AddCreatorToQuests < ActiveRecord::Migration[8.0]
  def change
    # Seeded quests have no creator; deleting an ace keeps the quests they made
    add_reference :quests, :creator, foreign_key: { to_table: :aces, on_delete: :nullify }
  end
end
