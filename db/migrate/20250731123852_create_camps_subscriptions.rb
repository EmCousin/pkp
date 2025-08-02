class CreateCampsSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :camps_subscriptions do |t|
      t.references :camp, foreign_key: true
      t.references :subscription, foreign_key: true

      t.timestamps
    end

    add_index :camps_subscriptions, [:camp_id, :subscription_id], unique: true
  end
end
