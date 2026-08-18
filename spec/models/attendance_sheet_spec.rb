# frozen_string_literal: true

require 'rails_helper'

describe AttendanceSheet, type: :model do
  it 'cannot move attendance records to another course' do
    course = create(:course)
    attendance_sheet = AttendanceSheet.create!(course:, date: Date.current)
    AttendanceRecord.create!(attendance_sheet:, member: create(:member, platform: course.platform))
    other_course = create(:course, category: course.category)

    expect(attendance_sheet.update(course: other_course)).to be false
    expect(attendance_sheet.errors.of_kind?(:course, :locked)).to be true
  end

  it 'cannot move an attendance sheet to a course on another platform' do
    attendance_sheet = AttendanceSheet.create!(course: create(:course), date: Date.current)
    other_platform = create(:platform, name: 'Other platform')
    other_category = create(:category, platform: other_platform, title: 'Other category')
    other_course = create(:course, category: other_category)

    expect(attendance_sheet.update(course: other_course)).to be false
    expect(attendance_sheet.errors.of_kind?(:course, :platform_locked)).to be true
  end
end
