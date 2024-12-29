# frozen_string_literal: true

module Admin
  class AttendanceSheetsController < AdminController
    before_action :set_course, only: %i[create]
    before_action :set_attendance_sheet, only: %i[show update]

    def show
      @attendance_records = @attendance_sheet.attendance_records.includes(member: :avatar_attachment).order('members.level')
    end

    def create
      @attendance_sheet = AttendanceSheet.find_or_create_for_course(@course)
      redirect_to admin_attendance_sheet_path(@attendance_sheet), status: :see_other
    end

    def update
      @attendance_record = @attendance_sheet.attendance_records.find(params[:record_id])
      @attendance_record.update(absent: params[:absent])

      redirect_to admin_attendance_sheet_path(@attendance_sheet), status: :see_other
    end

    private

    def set_course
      @course = Course.find(params[:course_id])
    end

    def set_attendance_sheet
      @attendance_sheet = AttendanceSheet.find(params[:id])
    end
  end
end
