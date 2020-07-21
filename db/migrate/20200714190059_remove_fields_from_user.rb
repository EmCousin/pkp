class RemoveFieldsFromUser < ActiveRecord::Migration[6.0]
  def change
    remove_column :users, :first_name, :string, index: true
    remove_column :users, :last_name, :string, index: true
    remove_column :users, :birthdate, :date
    remove_column :users, :contact_name, :string
    remove_column :users, :contact_phone_number, :string
    remove_column :users, :contact_relationship, :string
    remove_column :users, :agreed_to_publicity_right, :boolean, default: false

    change_column_null :users, :phone_number, true
    change_column_null :users, :address, true
    change_column_null :users, :zip_code, true
    change_column_null :users, :city, true
    change_column_null :users, :country, true
  end
end
