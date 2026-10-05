class AddSeasonalRostersAndEntityCodes < ActiveRecord::Migration[8.1]
  CODED_TABLES = %i[
    sports countries states cities stadiums leagues conferences divisions teams
    years seasons campaigns players activations contracts
  ].freeze

  CAMPAIGN_SNAPSHOT_FIELDS = %i[
    display_name territory mascot abbreviation logo_url primary_color secondary_color
  ].freeze

  CAMPAIGN_SNAPSHOT_REFERENCES = %i[stadium city conference division].freeze

  def up
    CAMPAIGN_SNAPSHOT_FIELDS.each { |field| add_column :campaigns, field, :string }
    CAMPAIGN_SNAPSHOT_REFERENCES.each do |reference|
      add_reference :campaigns, reference, foreign_key: true
    end
    add_column :campaigns, :details, :jsonb, default: {}, null: false
    add_column :seasons, :label, :string
    add_reference :players, :sport, foreign_key: true

    add_reference :activations, :player, foreign_key: true
    execute <<~SQL
      UPDATE activations
      SET player_id = contracts.player_id
      FROM contracts
      WHERE activations.contract_id = contracts.id
    SQL

    guard_legacy_activations!
    change_column_null :activations, :player_id, false
    change_column_null :activations, :contract_id, true
    add_index :activations, [:player_id, :campaign_id], unique: true

    CODED_TABLES.each do |table|
      add_column table, :entity_code, :string
      add_index table, :entity_code, unique: true
    end

    create_table :entity_codes do |t|
      t.string :namespace, null: false
      t.string :catalog, null: false
      t.string :code, null: false
      t.string :canonical_code, null: false
      t.references :record, polymorphic: true
      t.timestamps
    end
    add_index :entity_codes, [:namespace, :catalog, :code], unique: true
    add_index :entity_codes, [:namespace, :catalog, :canonical_code]
  end

  def down
    if select_value("SELECT COUNT(*) FROM activations WHERE contract_id IS NULL").to_i.positive?
      raise ActiveRecord::MigrationError,
        "Contract-free roster memberships exist; rollback cannot restore required contracts without losing data."
    end

    drop_table :entity_codes
    CODED_TABLES.reverse_each { |table| remove_column table, :entity_code }
    remove_index :activations, [:player_id, :campaign_id]
    change_column_null :activations, :contract_id, false
    remove_reference :activations, :player, foreign_key: true
    remove_reference :players, :sport, foreign_key: true
    remove_column :seasons, :label
    remove_column :campaigns, :details
    CAMPAIGN_SNAPSHOT_REFERENCES.reverse_each do |reference|
      remove_reference :campaigns, reference, foreign_key: true
    end
    CAMPAIGN_SNAPSHOT_FIELDS.reverse_each { |field| remove_column :campaigns, field }
  end

  private

  def guard_legacy_activations!
    if select_value("SELECT COUNT(*) FROM activations WHERE player_id IS NULL").to_i.positive?
      raise ActiveRecord::MigrationError,
        "Some legacy activations have no contract player; reconcile them before migrating. No rows were removed."
    end

    duplicate = select_one <<~SQL
      SELECT player_id, campaign_id
      FROM activations
      GROUP BY player_id, campaign_id
      HAVING COUNT(*) > 1
      LIMIT 1
    SQL
    return unless duplicate

    raise ActiveRecord::MigrationError,
      "Legacy activations duplicate player #{duplicate.fetch('player_id')} in campaign #{duplicate.fetch('campaign_id')}; " \
      "reconcile whole-season memberships before migrating. No rows were removed."
  end
end
