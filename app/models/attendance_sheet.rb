# frozen_string_literal: true

class AttendanceSheet < ApplicationRecord
  belongs_to :course
  has_many :attendance_records, dependent: :destroy

  validates :date, presence: true, uniqueness: { scope: :course_id }

  def self.find_or_create_for_course(course)
    sheet = find_or_create_by!(
      course:,
      date: Time.current
    )

    # Create attendance records for all active subscribers
    course.subscriptions.active.each do |subscription|
      sheet.attendance_records.find_or_create_by!(member: subscription.member)
    end

    sheet
  end
end
