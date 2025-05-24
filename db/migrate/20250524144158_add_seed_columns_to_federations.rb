class AddSeedColumnsToFederations < ActiveRecord::Migration[8.0]
  def change
    add_column :federations, :seed_version, :string, comment: 'Version of the seed file that created or last updated this record'
    add_column :federations, :last_seeded_at, :datetime, comment: 'When this record was last updated by a seed'
    add_index :federations, :seed_version
  end
end
