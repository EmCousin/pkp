# frozen_string_literal: true

class AddPennylaneBilling < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :pennylane_customer_id, :bigint
    add_index :users, :pennylane_customer_id, unique: true

    add_column :subscriptions, :pennylane_invoice_id, :bigint
    add_column :subscriptions, :pennylane_invoice_number, :string
    add_column :subscriptions, :pennylane_invoice_requested_at, :datetime
    add_column :subscriptions, :pennylane_invoiced_at, :datetime
    add_column :subscriptions, :pennylane_invoice_error, :text
    add_index :subscriptions, :pennylane_invoice_id, unique: true
  end
end
