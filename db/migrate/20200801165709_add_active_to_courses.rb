class AddActiveToCourses < ActiveRecord::Migration[6.0]
  def change
    add_column :courses, :active, :boolean, default: true, index: true
  end
end
