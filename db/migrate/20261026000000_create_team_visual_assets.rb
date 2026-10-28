class CreateTeamVisualAssets < ActiveRecord::Migration[8.1]
  def change
    %i[logos uniforms].each do |table|
      create_table table do |t|
        t.references :team, null: false, foreign_key: true
        t.string :name, null: false
        t.string :role
        t.date :start_date
        t.date :end_date
        t.boolean :ongoing, null: false, default: false
        t.jsonb :source, null: false, default: {}
        t.jsonb :details, null: false, default: {}
        t.string :entity_code
        t.timestamps
        t.index :entity_code, unique: true
      end
      add_check_constraint table, "start_date IS NULL OR end_date IS NULL OR end_date >= start_date", name: "#{table}_ordered_dates"
      add_check_constraint table, "NOT ongoing OR end_date IS NULL", name: "#{table}_ongoing_without_end"
    end

    create_table :uniform_pieces do |t|
      t.references :uniform, null: false, foreign_key: true
      t.string :name, null: false
      t.jsonb :source, null: false, default: {}
      t.jsonb :details, null: false, default: {}
      t.string :entity_code
      t.timestamps
      t.index :entity_code, unique: true
      t.index [ :uniform_id, :name ], unique: true
    end

    create_table :uniform_campaigns do |t|
      t.references :uniform, null: false, foreign_key: true
      t.references :campaign, null: false, foreign_key: true
      t.string :entity_code
      t.timestamps
      t.index :entity_code, unique: true
      t.index [ :uniform_id, :campaign_id ], unique: true
    end

    create_table :asset_representations do |t|
      t.references :subject, polymorphic: true, null: false
      t.string :file_format, null: false
      t.string :view, null: false, default: "default"
      t.string :canonical_path, null: false
      t.string :content_type, null: false
      t.string :sha256, null: false
      t.bigint :byte_size, null: false
      t.jsonb :source, null: false, default: {}
      t.jsonb :details, null: false, default: {}
      t.string :entity_code
      t.timestamps
      t.index :entity_code, unique: true
      t.index [ :subject_type, :subject_id, :file_format, :view ], unique: true, name: "unique_asset_representation"
    end
    add_check_constraint :asset_representations, "subject_type IN ('Logo', 'Uniform', 'UniformPiece')", name: "asset_subject_type"
    add_check_constraint :asset_representations, "byte_size > 0", name: "asset_file_not_empty"
    add_check_constraint :asset_representations, "sha256 ~ '^[a-f0-9]{64}$'", name: "asset_sha256_format"
  end
end
