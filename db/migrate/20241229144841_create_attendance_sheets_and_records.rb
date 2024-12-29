class CreateAttendanceSheetsAndRecords < ActiveRecord::Migration[7.0]
  def change
    create_table :attendance_sheets do |t|
      t.references :course, null: false, foreign_key: true
      t.date :date, null: false
      t.timestamps

      t.index [:course_id, :date], unique: true
    end

    create_table :attendance_records do |t|
      t.references :attendance_sheet, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.boolean :absent, default: true
      t.timestamps

      t.index [:attendance_sheet_id, :member_id], unique: true
    end
  end
end
