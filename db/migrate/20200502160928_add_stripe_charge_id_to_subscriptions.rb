class AddStripeChargeIdToSubscriptions < ActiveRecord::Migration[6.0]
  def change
    add_column :subscriptions, :stripe_charge_id, :string
  end
end
