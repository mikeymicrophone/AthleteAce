class RequireContractOrganizations < ActiveRecord::Migration[8.1]
  def up
    if select_value("SELECT COUNT(*) FROM contracts WHERE organization_id IS NULL").to_i.positive?
      raise ActiveRecord::MigrationError,
        "Some contracts still lack a verified organization. Map them before requiring organization contracts."
    end

    change_column_null :contracts, :organization_id, false
    remove_check_constraint :contracts, name: "contracts_have_a_counterparty"
  end

  def down
    add_check_constraint :contracts,
      "organization_id IS NOT NULL OR team_id IS NOT NULL",
      name: "contracts_have_a_counterparty"
    change_column_null :contracts, :organization_id, true
  end
end
