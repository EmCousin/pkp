class AddAttributesToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :birthdate, :date, null: false
    add_column :users, :phone_number, :string, null: false
    add_column :users, :address, :string, null: false
    add_column :users, :zip_code, :string, null: false
    add_column :users, :city, :string, null: false
    add_column :users, :country, :string, null: false
    add_column :users, :contact_name, :string, null: false
    add_column :users, :contact_phone_number, :string, null: false
    add_column :users, :contact_relationship, :string, null: false
    add_column :users, :agreed_to_publicity_right, :boolean, null: false
    add_column :users, :avatar, :string, null: false
  end
end
