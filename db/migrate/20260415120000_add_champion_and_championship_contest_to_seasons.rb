class AddChampionAndChampionshipContestToSeasons < ActiveRecord::Migration[8.0]
  def change
    add_reference :seasons, :champion, foreign_key: { to_table: :teams }
    add_reference :seasons, :championship_contest, foreign_key: { to_table: :contests }
  end
end
