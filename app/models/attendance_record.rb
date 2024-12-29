# frozen_string_literal: true

class AttendanceRecord < ApplicationRecord
  belongs_to :attendance_sheet
  has_one :course, through: :attendance_sheet
  belongs_to :member
  has_one :user, through: :member

  validates :member, uniqueness: { scope: :attendance_sheet_id }

  after_save :check_consecutive_absences, if: :absent?

  scope :recent, -> { order(created_at: :desc).limit(3) }

  private

  def check_consecutive_absences
    recent_records = member.attendance_records
                           .joins(:attendance_sheet)
                           .where(attendance_sheets: { course_id: attendance_sheet.course_id })
                           .recent

    return unless recent_records.count == 3 && recent_records.all?(&:absent?)

    AttendanceMailer.consecutive_absences(member, attendance_sheet.course).deliver_now
  end
end
