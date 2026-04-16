class CreateOrganizationsAndOrganizationAffiliations < ActiveRecord::Migration[8.0]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :abbreviation
      t.text :description
      t.string :url
      t.string :logo_url
      t.integer :founded_year

      t.timestamps
    end

    create_table :organization_affiliations do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.date :start_date
      t.date :end_date
      t.json :details

      t.timestamps
    end

    add_index :organization_affiliations, [:organization_id, :team_id, :start_date], unique: true, name: "index_org_affiliations_on_org_team_start"
  end
end
