# frozen_string_literal: true

class AddTombstonesToMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :members, :tombstoned_at, :datetime
    add_index :members, :tombstoned_at

    change_column_null :members, :first_name, true
    change_column_null :members, :last_name, true
    change_column_null :members, :birthdate, true
    change_column_null :members, :contact_name, true
    change_column_null :members, :contact_phone_number, true
    change_column_null :members, :contact_relationship, true
  end
end
