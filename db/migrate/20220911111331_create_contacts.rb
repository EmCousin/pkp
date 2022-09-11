class CreateContacts < ActiveRecord::Migration[7.0]
  def change
    create_table :contacts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :email, null: false
      t.datetime :confirmed_at

      t.timestamps
    end
  end
end
