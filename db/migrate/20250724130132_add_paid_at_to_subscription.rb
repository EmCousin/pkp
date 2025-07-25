class AddPaidAtToSubscription < ActiveRecord::Migration[8.0]
  def change
    create_enum :payment_method, %i[cash bank_transfer bank_check credit_card]

    add_column :subscriptions, :paid_at, :datetime
    add_column :subscriptions, :payment_method, :enum, enum_type: :payment_method

    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE subscriptions
          SET status = 5
          WHERE status = 4; -- temporary status 4: archived -> 5: archived

          UPDATE subscriptions
          SET paid_at = created_at,
              status = 2 -- confirmed
          WHERE status IN (1, 2, 3, 4); -- 1: confirmed_bank_check, 2: confirmed_cash, 3: confirmed_bank_transfer, 5: confirmed_credit_card

          UPDATE subscriptions
          SET payment_method = 'bank_check'
          WHERE status = 1;

          UPDATE subscriptions
          SET payment_method = 'cash'
          WHERE status = 2;

          UPDATE subscriptions
          SET payment_method = 'bank_transfer'
          WHERE status = 3;

          UPDATE subscriptions
          SET payment_method = 'credit_card'
          WHERE status = 4;

          UPDATE subscriptions
          SET status = 2
          WHERE status = 5; -- final status 5: archived -> 2: archived
        SQL
      end
    end
  end
end
