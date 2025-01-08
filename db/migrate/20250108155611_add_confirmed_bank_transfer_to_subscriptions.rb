class AddConfirmedBankTransferToSubscriptions < ActiveRecord::Migration[7.2]
  def up
    # Temporarily change archived status to 4
    execute <<-SQL
      UPDATE subscriptions
      SET status = 4
      WHERE status = 3
    SQL

    # Add new status confirmed_bank_transfer as 3
  end

  def down
    # Move archived status back to 3
    execute <<-SQL
      UPDATE subscriptions
      SET status = 3
      WHERE status = 4
    SQL

    # Remove confirmed_bank_transfer status
  end
end
