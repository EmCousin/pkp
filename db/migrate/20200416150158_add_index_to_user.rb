class AddIndexToUser < ActiveRecord::Migration[6.0]
  def change
    add_index :users, :first_name
    add_index :users, :last_name
  end
end
