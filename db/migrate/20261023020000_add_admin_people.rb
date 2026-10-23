class AddAdminPeople < ActiveRecord::Migration[8.1]
  def change
    add_column :aces, :suspended_at, :datetime
    add_column :aces, :account_version, :integer, null: false, default: 0
    add_column :aces, :session_version, :integer, null: false, default: 0
    create_table :account_actions do |t|
      t.references :ace, foreign_key: { on_delete: :nullify }
      t.references :actor, foreign_key: { to_table: :aces, on_delete: :nullify }
      t.string :ace_name, null: false
      t.string :action, null: false
      t.text :reason, null: false
      t.jsonb :before_state, null: false
      t.jsonb :after_state, null: false
      t.string :request_key, null: false, limit: 128
      t.datetime :created_at, null: false
    end
    add_index :account_actions, [ :actor_id, :request_key ], unique: true
    create_table :sign_in_events do |t|
      t.references :ace, null: false, foreign_key: { on_delete: :cascade }
      t.string :outcome, null: false
      t.string :ip_address, limit: 64
      t.string :user_agent, limit: 512
      t.datetime :created_at, null: false
    end
    add_index :sign_in_events, [ :ace_id, :created_at, :id ]
  end
end
