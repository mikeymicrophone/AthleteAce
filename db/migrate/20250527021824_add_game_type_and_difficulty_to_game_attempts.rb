class AddGameTypeAndDifficultyToGameAttempts < ActiveRecord::Migration[8.0]
  def change
    # The 'game_type' column was found to already exist in db/schema.rb
    # add_column :game_attempts, :game_type, :string

    # Add 'difficulty_level' if it doesn't exist. 
    # It's good practice to check if the column exists before adding it in migrations that might be re-run or adjusted.
    unless column_exists?(:game_attempts, :difficulty_level)
      add_column :game_attempts, :difficulty_level, :string
    end
  end
end
