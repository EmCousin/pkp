# frozen_string_literal: true

class AddPennylaneBilling < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    backfill_user_names
    change_column_null :users, :first_name, false
    change_column_null :users, :last_name, false

    add_column :users, :pennylane_customer_id, :bigint
    add_index :users, :pennylane_customer_id, unique: true

    create_table :invoices do |t|
      t.references :invoiceable, polymorphic: true, null: false, index: false
      t.string :provider, null: false, default: 'pennylane'
      t.string :state, null: false, default: 'pending'
      t.uuid :sync_token, null: false
      t.bigint :external_id
      t.string :number
      t.date :issue_date, null: false
      t.decimal :amount, null: false
      t.string :currency, null: false, default: 'EUR'
      t.string :vat_rate, null: false, default: 'FR_200'
      t.string :label, null: false
      t.text :description, null: false
      t.jsonb :customer_snapshot, null: false, default: {}
      t.jsonb :transaction_reference
      t.datetime :requested_at, null: false
      t.datetime :completed_at
      t.text :error

      t.timestamps
    end
    add_index :invoices, %i[invoiceable_type invoiceable_id], unique: true
    add_index :invoices, :external_id, unique: true
    add_index :invoices, :state
  end

  def down
    drop_table :invoices
    remove_index :users, :pennylane_customer_id
    remove_columns :users, :first_name, :last_name, :pennylane_customer_id
  end

  private

  def backfill_user_names
    execute <<~SQL.squish
      UPDATE users
      SET first_name = COALESCE(
            (SELECT members.first_name FROM members WHERE members.user_id = users.id ORDER BY members.created_at LIMIT 1),
            'Compte'
          ),
          last_name = COALESCE(
            (SELECT members.last_name FROM members WHERE members.user_id = users.id ORDER BY members.created_at LIMIT 1),
            'A completer'
          )
    SQL
  end
end
