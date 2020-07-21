class CreateMembers < ActiveRecord::Migration[6.0]
  def change
    create_table :members do |t|
      t.references :user, foreign_key: true, index: true
      t.string :first_name, index: true, null: false
      t.string :last_name, index: true, null: false
      t.date :birthdate, null: false
      t.string :contact_name, null: false
      t.string :contact_phone_number, null: false
      t.string :contact_relationship, null: false
      t.boolean :agreed_to_advertising_right, default: false, null: false

      t.timestamps
    end

    remove_reference :subscriptions, :member
    add_reference :subscriptions, :member, foreign_key: true, index: true
  end
end
