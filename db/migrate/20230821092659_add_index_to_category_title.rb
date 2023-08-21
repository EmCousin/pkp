class AddIndexToCategoryTitle < ActiveRecord::Migration[7.0]
  def change
    add_index :categories, :title, unique: true
  end
end
