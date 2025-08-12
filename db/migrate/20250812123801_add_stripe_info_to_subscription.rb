class AddStripeInfoToSubscription < ActiveRecord::Migration[8.0]
  def change
    add_column :subscriptions, :stripe_payment_intent_id, :string
  end
end
