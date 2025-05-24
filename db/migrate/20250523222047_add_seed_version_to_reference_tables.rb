class AddSeedVersionToReferenceTables < ActiveRecord::Migration[8.0]
  def change
    # Reference data models that are likely created by seeds
    reference_tables = [
      :sports,
      :leagues,
      :conferences,
      :divisions,
      :teams,
      :memberships,
      :players,
      :positions,
      :roles,
      :stadiums,
      :countries,
      :states,
      :cities,
      :spectrums,
      :quests,
      :achievements,
      :highlights
    ]
    
    # Add seed_version and last_seeded_at to each reference table
    reference_tables.each do |table_name|
      add_column table_name, :seed_version, :string, comment: 'Version of the seed file that created or last updated this record'
      add_column table_name, :last_seeded_at, :datetime, comment: 'When this record was last updated by a seed'
      add_index table_name, :seed_version
    end
  end
end
