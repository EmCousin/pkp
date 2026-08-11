# frozen_string_literal: true

class RequireUserNames < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_check_constraint :users, 'first_name IS NOT NULL', name: 'users_first_name_null', validate: false
    add_check_constraint :users, 'last_name IS NOT NULL', name: 'users_last_name_null', validate: false
    validate_check_constraint :users, name: 'users_first_name_null'
    validate_check_constraint :users, name: 'users_last_name_null'
    change_column_null :users, :first_name, false
    change_column_null :users, :last_name, false
    remove_check_constraint :users, name: 'users_first_name_null'
    remove_check_constraint :users, name: 'users_last_name_null'
    add_index :users, :pennylane_customer_id, unique: true, algorithm: :concurrently
  end

  def down
    remove_index :users, :pennylane_customer_id, algorithm: :concurrently
    change_column_null :users, :first_name, true
    change_column_null :users, :last_name, true
  end
end
