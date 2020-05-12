class CreateInvoices < ActiveRecord::Migration[6.0]
  def change
    create_table :invoices do |t|
      t.references :subscription, null: false, foreign_key: true, index: true
      t.string :file

      t.timestamps
    end
  end
end
