class ChangeMemberIndexes < ActiveRecord::Migration[6.0]
  def change
    remove_index :members, :first_name
    remove_index :members, :last_name

    add_index :members, %i[first_name last_name], unique: true
  end
end
