# frozen_string_literal: true

require 'rails_helper'

describe CourseUnavailabilityPeriod, type: :model do
  let(:course) { create(:course) }
  let(:platform) { course.platform }

  it 'makes both period boundaries unavailable' do
    period = create(:course_unavailability_period,
                    platform:,
                    courses: [course],
                    starts_on: Date.new(2026, 12, 21),
                    ends_on: Date.new(2027, 1, 4))

    expect(course).to be_unavailable_on(period.starts_on)
    expect(course).to be_unavailable_on(period.ends_on)
    expect(course).not_to be_unavailable_on(period.starts_on - 1.day)
    expect(course).not_to be_unavailable_on(period.ends_on + 1.day)
  end

  it 'allows overlapping periods' do
    create(:course_unavailability_period,
           platform:,
           courses: [course],
           starts_on: Date.new(2026, 12, 21),
           ends_on: Date.new(2027, 1, 4))
    overlapping = build(:course_unavailability_period,
                        platform:,
                        courses: [course],
                        starts_on: Date.new(2027, 1, 1),
                        ends_on: Date.new(2027, 1, 8))

    expect(overlapping).to be_valid
  end

  it 'requires at least one course' do
    period = build(:course_unavailability_period, platform:, courses: [])

    expect(period).not_to be_valid
    expect(period.errors.of_kind?(:courses, :blank)).to be true
  end

  it 'rejects an end date before the start date' do
    period = build(:course_unavailability_period,
                   platform:,
                   courses: [course],
                   starts_on: Date.new(2027, 1, 5),
                   ends_on: Date.new(2027, 1, 4))

    expect(period).not_to be_valid
    expect(period.errors.of_kind?(:ends_on, :before_starts_on)).to be true
  end

  it 'rejects a course from another platform' do
    other_course = create(:course, category: create(:category, platform: create(:platform, name: 'Other platform'), title: 'Other category'))
    period = build(:course_unavailability_period, platform:, courses: [course, other_course])

    expect(period).not_to be_valid
    expect(period.errors.of_kind?(:courses, :wrong_platform)).to be true
  end
end
