# frozen_string_literal: true

module AttendanceSheetsControllerConcern
  extend ActiveSupport::Concern

  included do
    before_action :set_course, only: %i[create]
    before_action :set_attendance_sheet, only: %i[show update]
  end

  def show
    @attendance_records = @attendance_sheet.attendance_records
                                           .includes(member: :avatar_attachment)
                                           .order('members.level', 'members.first_name', 'members.last_name')
  end

  def create
    @attendance_sheet = AttendanceSheet.find_or_create_for_course(@course)
    redirect_to polymorphic_path([namespace, @attendance_sheet]), status: :see_other
  end

  def update
    @attendance_record = @attendance_sheet.attendance_records.find(params[:record_id])
    @attendance_record.update(absent: params[:absent])

    redirect_to polymorphic_path([namespace, @attendance_sheet]), status: :see_other
  end

  private

  def namespace
    controller_path.split('/').first.to_sym
  end

  def set_course
    @course = Course.featuring_attendance_sheet.find(params[:course_id])
  end

  def set_attendance_sheet
    @attendance_sheet = AttendanceSheet.find(params[:id])
  end
end
