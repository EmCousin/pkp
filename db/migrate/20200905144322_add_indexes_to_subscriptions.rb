class AddIndexesToSubscriptions < ActiveRecord::Migration[6.0]
  def change
    add_index :subscriptions, :status
    add_index :subscriptions, :created_at, order: { created_at: :desc }
  end
end
