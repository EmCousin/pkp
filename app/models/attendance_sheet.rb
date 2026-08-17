# frozen_string_literal: true

class AttendanceSheet < ApplicationRecord
  belongs_to :course
  has_many :attendance_records, dependent: :destroy

  validates :date, presence: true, uniqueness: { scope: :course_id }
  validate :course_cannot_change_with_records, if: :will_save_change_to_course_id?

  class << self
    def find_or_create_for_course(course, date = Time.current.to_date)
      sheet = find_or_create_by!(
        course:,
        date:
      )

      create_attendance_records(sheet, course)

      sheet
    end

    def create_attendance_records(sheet, course)
      AttendanceRecord.upsert_all( # rubocop:disable Rails/SkipsModelValidations
        course.subscriptions.confirmed.filter_by_year(Subscription.current_year(sheet.date)).map do |subscription|
          {
            attendance_sheet_id: sheet.id,
            member_id: subscription.member_id
          }
        end,
        unique_by: %i[attendance_sheet_id member_id]
      )
    end
  end

  private

  def course_cannot_change_with_records
    return unless persisted? && attendance_records.exists?

    errors.add(:course, :locked)
  end
end
