# frozen_string_literal: true

class AddPennylaneBilling < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :pennylane_customer_id, :bigint

    create_table :billing_invoices do |t|
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
    add_index :billing_invoices, %i[invoiceable_type invoiceable_id], unique: true
    add_index :billing_invoices, :external_id, unique: true
    add_index :billing_invoices, :state
  end
end
