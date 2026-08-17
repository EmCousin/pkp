# frozen_string_literal: true

require 'rails_helper'

describe AttendanceSheet, type: :model do
  it 'cannot move attendance records to another course' do
    course = create(:course)
    attendance_sheet = AttendanceSheet.create!(course:, date: Date.current)
    AttendanceRecord.create!(attendance_sheet:, member: create(:member, platform: course.platform))
    other_platform = create(:platform, name: 'Other platform')
    other_category = create(:category, platform: other_platform, title: 'Other category')
    other_course = create(:course, category: other_category)

    expect(attendance_sheet.update(course: other_course)).to be false
    expect(attendance_sheet.errors.of_kind?(:course, :locked)).to be true
  end
end
