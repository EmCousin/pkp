class AddStatusToAttendanceRecord < ActiveRecord::Migration[8.0]
  def change
    create_enum "attendance_record_status", ["present", "absent", "excused"]

    add_column :attendance_records, :status, :enum, default: "present", null: false, enum_type: "attendance_record_status"

    reversible do |dir|
      dir.up do
        execute(
          <<-SQL
            UPDATE attendance_records
            SET status = 'present'
            WHERE absent = false;

            UPDATE attendance_records
            SET status = 'absent'
            WHERE absent = true;
          SQL
        )
      end

      dir.down do
        execute(
          <<-SQL
            UPDATE attendance_records
            SET absent = false
            WHERE status = 'present';

            UPDATE attendance_records
            SET absent = true
            WHERE status = 'absent';
          SQL
        )
      end
    end

    add_index :attendance_records, :status

    remove_column :attendance_records, :absent, :boolean, default: true
  end
end
