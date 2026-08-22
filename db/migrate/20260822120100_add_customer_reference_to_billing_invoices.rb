# frozen_string_literal: true

class AddCustomerReferenceToBillingInvoices < ActiveRecord::Migration[8.1]
  def up
    add_column :billing_invoices, :customer_reference, :string

    execute <<~SQL.squish
      UPDATE billing_invoices
      SET customer_reference = 'pkp-user-' || members.user_id
      FROM subscriptions
      INNER JOIN members ON members.id = subscriptions.member_id
      WHERE billing_invoices.invoiceable_type = 'Subscription'
        AND billing_invoices.invoiceable_id = subscriptions.id
    SQL

    change_column_null :billing_invoices, :customer_reference, false
  end

  def down
    remove_column :billing_invoices, :customer_reference
  end
end
