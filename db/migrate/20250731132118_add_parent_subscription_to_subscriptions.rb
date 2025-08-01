class AddParentSubscriptionToSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_reference :subscriptions, :parent_subscription, foreign_key: { to_table: :subscriptions }
  end
end
