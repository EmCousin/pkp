class AddOpenToCamps < ActiveRecord::Migration[8.0]
  def change
    add_column :camps, :open, :boolean, default: false, null: false
  end
end
