class AddFeaturesAttendanceSheetToCourse < ActiveRecord::Migration[7.2]
  def change
    add_column :courses, :features_attendance_sheet, :boolean, default: false, null: false
  end
end
