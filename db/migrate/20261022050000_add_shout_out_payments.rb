class AddShoutOutPayments < ActiveRecord::Migration[8.1]
  def change
    create_table :credit_accounts do |t|
      t.references :ace, null: false, foreign_key: true, index: { unique: true }
      t.bigint :available_cents, null: false, default: 0
      t.bigint :reserved_cents, null: false, default: 0
      t.timestamps
    end
    add_check_constraint :credit_accounts, "available_cents >= 0 AND reserved_cents >= 0", name: "credit_nonnegative"
    create_table :shout_outs do |t|
      t.references :created_by, null: false, foreign_key: { to_table: :aces }
      t.references :target, polymorphic: true
      t.references :team, foreign_key: { on_delete: :nullify }
      t.references :league, foreign_key: { on_delete: :nullify }
      t.references :shout_out_draft, foreign_key: { on_delete: :nullify }
      t.integer :draft_revision, null: false
      t.string :target_name, null: false
      t.text :message, null: false
      t.bigint :bid_cents, null: false
      t.string :payment_method, null: false
      t.string :funding_status, null: false, default: "unfunded"
      t.string :moderation_status, null: false, default: "pending"
      t.integer :moderation_revision, null: false, default: 1
      t.timestamps
    end
    add_index :shout_outs, [ :shout_out_draft_id, :draft_revision ], unique: true
    add_check_constraint :shout_outs, "bid_cents > 0", name: "positive_shout_out_bid"
    add_check_constraint :shout_outs, "payment_method IN ('credit', 'stripe') AND funding_status IN ('unfunded', 'reserved', 'spent', 'refunded')", name: "shout_out_funding_states"
    create_table :stripe_purchases do |t|
      t.references :ace, null: false, foreign_key: true
      t.references :shout_out, foreign_key: true
      t.bigint :amount_cents, null: false
      t.string :request_key, null: false
      t.string :status, null: false, default: "pending"
      t.string :stripe_session_id
      t.string :stripe_payment_intent_id
      t.timestamps
    end
    add_index :stripe_purchases, [ :ace_id, :request_key ], unique: true
    add_index :stripe_purchases, :stripe_session_id, unique: true
    add_index :stripe_purchases, :stripe_payment_intent_id, unique: true
    add_check_constraint :stripe_purchases, "amount_cents BETWEEN 50 AND 99999999 AND status IN ('pending', 'paid', 'expired')", name: "stripe_purchase_amount_and_status"
    create_table :credit_entries do |t|
      t.references :credit_account, null: false, foreign_key: true
      t.references :source, polymorphic: true, null: false
      t.string :operation_key, null: false, index: { unique: true }
      t.string :kind, null: false
      t.bigint :available_delta, null: false
      t.bigint :reserved_delta, null: false
      t.timestamps
    end
  end
end
