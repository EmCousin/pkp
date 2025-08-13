# frozen_string_literal: true

module AttendanceRecordsControllerConcern
  extend ActiveSupport::Concern

  included do
    before_action :set_attendance_sheet
    before_action :set_attendance_record
  end

  def update
    @attendance_record.update(attendance_record_params)
    redirect_to polymorphic_path([namespace, @attendance_sheet]), status: :see_other
  end

  private

  def attendance_record_params
    params.expect(attendance_record: [:status])
  end

  def namespace
    controller_path.split('/').first.to_sym
  end

  def set_attendance_sheet
    @attendance_sheet = AttendanceSheet.find(params[:attendance_sheet_id])
  end

  def set_attendance_record
    @attendance_record = @attendance_sheet.attendance_records.find(params[:id])
  end
end
