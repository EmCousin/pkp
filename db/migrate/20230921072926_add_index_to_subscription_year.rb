class AddIndexToSubscriptionYear < ActiveRecord::Migration[7.0]
  def change
    add_index :subscriptions, :year
  end
end
