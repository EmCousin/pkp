class AddInvoiceToSubscriptions < ActiveRecord::Migration[6.0]
  def change
    add_column :subscriptions, :invoice, :string
  end
end
