class AddUniqueIndexToSubscriptionPerMemberAndYear < ActiveRecord::Migration[8.0]
  def change
    add_index :subscriptions, [:member_id, :year], unique: true
  end
end
