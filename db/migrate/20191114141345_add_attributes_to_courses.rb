class AddAttributesToCourses < ActiveRecord::Migration[5.2]
  def change
  	add_column :courses, :weekday, :integer
  	Course.update_all weekday: 1
  	change_column_null :courses, :weekday, false
  end
end
