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

  it 'requires confirmation for active discovery sessions in the period' do
    course.update!(active: true, discovery_enabled: true, discovery_price: 25, discovery_capacity: 12, weekday: :samedi)
    session = create(:discovery_session,
                     course:,
                     occurs_on: Date.new(2027, 1, 2),
                     starts_at: Time.zone.local(2027, 1, 2, 12))
    legacy_session = create(:discovery_session, course:, starts_at: Time.zone.local(2027, 1, 3, 12))
    create(:discovery_registration, discovery_session: session, status: :confirmed)
    create(:discovery_registration, discovery_session: session, status: :archived)
    create(:discovery_session, course:, starts_at: Time.zone.local(2027, 1, 4, 12), active: false)
    period = build(:course_unavailability_period,
                   platform:,
                   courses: [course],
                   starts_on: Date.new(2027, 1, 1),
                   ends_on: Date.new(2027, 1, 4))

    expect(period.save_with_course_locks).to be false
    expect(period).not_to be_persisted
    expect(period.conflicting_discovery_sessions).to contain_exactly(session, legacy_session)
    expect(period.conflicting_discovery_sessions.first.subscriptions.count(&:confirmed?)).to eq(1)

    confirmed_ids = [session.id, legacy_session.id]
    expect(period.save_with_course_locks(confirm_conflicts: true, confirmed_conflict_ids: confirmed_ids)).to be true
  end
end
