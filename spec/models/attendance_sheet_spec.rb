# frozen_string_literal: true

require 'rails_helper'

describe AttendanceSheet, type: :model do
  it 'does not create a regular sheet on an unavailable date' do
    course = create(:course)
    create(:course_unavailability_period, platform: course.platform, courses: [course], starts_on: Date.current, ends_on: Date.current)

    sheet = described_class.find_or_create_for_regular_course(course)

    expect(sheet).not_to be_persisted
    expect(sheet.errors.of_kind?(:date, :unavailable)).to be true
  end

  it 'returns an existing regular sheet on an unavailable date' do
    course = create(:course)
    sheet = described_class.create!(course:, date: Date.current)
    create(:course_unavailability_period, platform: course.platform, courses: [course], starts_on: Date.current, ends_on: Date.current)

    expect(described_class.find_or_create_for_regular_course(course)).to eq(sheet)
  end

  it 'creates a discovery sheet on an unavailable date' do
    discovery_session = create(:discovery_session)
    date = discovery_session.occurrence_date
    create(:course_unavailability_period,
           platform: discovery_session.platform,
           courses: [discovery_session.course],
           starts_on: date,
           ends_on: date)

    sheet = described_class.find_or_create_for_discovery_session(discovery_session)

    expect(sheet).to be_persisted
    expect(sheet).to have_attributes(course: discovery_session.course, date:)
  end

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
