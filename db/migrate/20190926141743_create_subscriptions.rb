class CreateSubscriptions < ActiveRecord::Migration[5.2]
  def change
    create_table :subscriptions do |t|
      t.references :member, foreign_key: true, index: true
      t.integer :year, null: false
      t.decimal :fee, null: false

      t.timestamps
    end
  end
end
