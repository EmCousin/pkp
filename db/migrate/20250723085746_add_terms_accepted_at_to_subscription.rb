class AddTermsAcceptedAtToSubscription < ActiveRecord::Migration[8.0]
  def change
    add_column :subscriptions, :terms_accepted_at, :datetime
    add_column :subscriptions, :doctor_certified_at, :datetime

    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE subscriptions
          SET terms_accepted_at = created_at, doctor_certified_at = created_at
          WHERE status IN (1, 2, 3) -- confirmed_bank_check, confirmed_cash, confirmed_bank_transfer;
        SQL
      end
    end
  end
end
