class AddCoachToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :coach, :boolean, default: false, null: false
  end
end
