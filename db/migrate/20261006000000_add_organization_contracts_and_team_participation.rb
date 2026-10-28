class AddOrganizationContractsAndTeamParticipation < ActiveRecord::Migration[8.1]
  EXISTING_CODED_TABLES = %i[organizations organization_affiliations contests contestants].freeze

  def up
    add_reference :contracts, :organization, foreign_key: true
    change_column_null :contracts, :team_id, true
    add_check_constraint :contracts,
      "organization_id IS NOT NULL OR team_id IS NOT NULL",
      name: "contracts_have_a_counterparty"

    EXISTING_CODED_TABLES.each do |table|
      add_column table, :entity_code, :string
      add_index table, :entity_code, unique: true
    end

    add_column :contests, :kind, :string
    add_index :contests, [ :kind, :begin_date ]

    create_table :transactions do |t|
      t.string :kind, null: false
      t.date :effective_on
      t.jsonb :source, default: {}, null: false
      t.jsonb :details, default: {}, null: false
      t.string :entity_code
      t.timestamps
    end
    add_index :transactions, :entity_code, unique: true
    add_index :transactions, [ :effective_on, :kind ]

    create_table :transaction_players do |t|
      t.references :transaction, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.references :from_organization, foreign_key: { to_table: :organizations }
      t.references :to_organization, foreign_key: { to_table: :organizations }
      t.references :from_team, foreign_key: { to_table: :teams }
      t.references :to_team, foreign_key: { to_table: :teams }
      t.jsonb :details, default: {}, null: false
      t.string :entity_code
      t.timestamps
    end
    add_index :transaction_players, [ :transaction_id, :player_id ], unique: true
    add_index :transaction_players, :entity_code, unique: true

    create_table :stints do |t|
      t.references :player, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.references :contract, foreign_key: true
      t.date :start_date
      t.date :end_date
      t.string :status
      t.references :start_transaction, foreign_key: { to_table: :transactions }
      t.references :end_transaction, foreign_key: { to_table: :transactions }
      t.jsonb :source, default: {}, null: false
      t.jsonb :details, default: {}, null: false
      t.string :entity_code
      t.timestamps
    end
    add_index :stints, :entity_code, unique: true
    add_index :stints, [ :team_id, :start_date, :end_date ]
    add_index :stints, [ :player_id, :start_date, :end_date ]
    add_check_constraint :stints,
      "start_date IS NULL OR end_date IS NULL OR end_date >= start_date",
      name: "stints_have_ordered_dates"

    create_table :rosters do |t|
      t.references :campaign, null: false, foreign_key: true
      t.string :kind, null: false
      t.date :effective_on
      t.datetime :observed_at
      t.string :coverage, default: "unknown", null: false
      t.jsonb :source, default: {}, null: false
      t.jsonb :details, default: {}, null: false
      t.string :entity_code
      t.timestamps
    end
    add_index :rosters, :entity_code, unique: true
    add_index :rosters, [ :campaign_id, :kind, :effective_on ]
    add_check_constraint :rosters,
      "coverage IN ('unknown', 'partial', 'complete')",
      name: "rosters_have_known_coverage_labels"

    create_table :roster_entries do |t|
      t.references :roster, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.references :stint, foreign_key: true
      t.string :status
      t.string :jersey_number
      t.jsonb :source, default: {}, null: false
      t.jsonb :details, default: {}, null: false
      t.string :entity_code
      t.timestamps
    end
    add_index :roster_entries, [ :roster_id, :player_id ], unique: true
    add_index :roster_entries, :entity_code, unique: true

    create_table :appearances do |t|
      t.references :player, null: false, foreign_key: true
      t.references :contestant, null: false, foreign_key: true
      t.references :stint, foreign_key: true
      t.boolean :starter
      t.string :jersey_number
      t.jsonb :statistics, default: {}, null: false
      t.jsonb :source, default: {}, null: false
      t.jsonb :details, default: {}, null: false
      t.string :entity_code
      t.timestamps
    end
    add_index :appearances, [ :contestant_id, :player_id ], unique: true
    add_index :appearances, :entity_code, unique: true
  end

  def down
    if select_value("SELECT COUNT(*) FROM contracts WHERE team_id IS NULL").to_i.positive?
      raise ActiveRecord::MigrationError,
        "Organization-only contracts exist; restore verified legacy team mappings before rollback."
    end

    drop_table :appearances
    drop_table :roster_entries
    drop_table :rosters
    drop_table :stints
    drop_table :transaction_players
    drop_table :transactions
    remove_index :contests, [ :kind, :begin_date ]
    remove_column :contests, :kind, :string
    EXISTING_CODED_TABLES.reverse_each do |table|
      remove_index table, :entity_code
      remove_column table, :entity_code, :string
    end
    remove_check_constraint :contracts, name: "contracts_have_a_counterparty"
    change_column_null :contracts, :team_id, false
    remove_reference :contracts, :organization, foreign_key: true
  end
end
