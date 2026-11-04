# frozen_string_literal: true

require 'rails_helper'

describe 'Admin course unavailability periods', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:platform) { Platform.find_by!(domain: 'example.com') }
  let!(:course) { create(:course, :discoverable, category: create(:category, platform:)) }

  before { sign_in create(:user, :admin, phone_number: '+33612345679') }

  def conflict_confirmation_token
    response.parsed_body.at_css('input[name="conflict_confirmation_token"]')['value']
  end

  it 'creates, displays, updates, and deletes a period' do
    get new_admin_course_unavailability_period_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('type="date"', course.title)

    expect do
      post admin_course_unavailability_periods_path, params: {
        course_unavailability_period: {
          starts_on: '2026-12-21',
          ends_on: '2027-01-04',
          course_ids: [course.id]
        }
      }
    end.to change(CourseUnavailabilityPeriod, :count).by(1)

    period = CourseUnavailabilityPeriod.last
    expect(response).to redirect_to(admin_course_unavailability_period_path(period))

    get admin_course_unavailability_period_path(period)
    expect(response.body).to include(course.title)

    patch admin_course_unavailability_period_path(period), params: {
      course_unavailability_period: {
        starts_on: '2026-12-22',
        ends_on: '2027-01-05',
        course_ids: [course.id]
      }
    }
    expect(response).to redirect_to(admin_course_unavailability_period_path(period))
    expect(period.reload).to have_attributes(starts_on: Date.new(2026, 12, 22), ends_on: Date.new(2027, 1, 5))

    expect do
      delete admin_course_unavailability_period_path(period)
    end.to change(CourseUnavailabilityPeriod, :count).by(-1)
  end

  it 'renders validation errors without JavaScript' do
    post admin_course_unavailability_periods_path, params: {
      course_unavailability_period: {
        starts_on: '2027-01-05',
        ends_on: '2027-01-04',
        course_ids: []
      }
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('Date de fin', 'Cours concernés')
  end

  it 'rejects a forged course from another platform' do
    other_platform = create(:platform, name: 'Other platform')
    other_course = create(:course, title: 'Other course', category: create(:category, platform: other_platform, title: 'Other category'))

    expect do
      post admin_course_unavailability_periods_path, params: {
        course_unavailability_period: {
          starts_on: '2026-12-21',
          ends_on: '2027-01-04',
          course_ids: [other_course.id]
        }
      }
    end.not_to change(CourseUnavailabilityPeriod, :count)

    expect(response).to have_http_status(:unprocessable_content)
  end

  it 'does not replace courses with a forged course from another platform' do
    period = create(:course_unavailability_period, platform:, courses: [course])
    other_platform = create(:platform, name: 'Other platform')
    other_course = create(:course, category: create(:category, platform: other_platform, title: 'Other category'))

    patch admin_course_unavailability_period_path(period), params: {
      course_unavailability_period: {
        starts_on: period.starts_on,
        ends_on: period.ends_on,
        course_ids: [other_course.id]
      }
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(period.reload.courses).to contain_exactly(course)
  end

  it 'does not expose another platform period' do
    other_platform = create(:platform, name: 'Other platform')
    other_course = create(:course, category: create(:category, platform: other_platform, title: 'Other category'))
    period = create(:course_unavailability_period, platform: other_platform, courses: [other_course])

    get admin_course_unavailability_period_path(period)

    expect(response).to have_http_status(:not_found)
  end

  it 'warns before creating a period that conflicts with active discovery sessions' do
    discovery_session = create(:discovery_session, course:, starts_at: Time.zone.local(2026, 12, 22, 12))
    create_list(:discovery_registration, 2, discovery_session:, status: :confirmed)
    create(:discovery_registration, discovery_session:, status: :pending)

    expect do
      post admin_course_unavailability_periods_path, params: {
        course_unavailability_period: {
          starts_on: '2026-12-21',
          ends_on: '2027-01-04',
          course_ids: [course.id]
        }
      }
    end.not_to change(CourseUnavailabilityPeriod, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include(course.title, '22 décembre 2026', '2 inscriptions confirmées')
    confirmation_token = conflict_confirmation_token

    edit_link = response.parsed_body.xpath('//a').find { |link| link.text.include?('Modifier la période') }
    get edit_link['href']
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('value="2026-12-21"', 'value="2027-01-04"')

    expect do
      post admin_course_unavailability_periods_path, params: {
        course_unavailability_period: {
          starts_on: '2026-12-21',
          ends_on: '2027-01-04',
          course_ids: [course.id]
        },
        conflict_confirmation_token: confirmation_token
      }
    end.to change(CourseUnavailabilityPeriod, :count).by(1)
  end

  it 'warns again when a conflicting session appears after the create warning' do
    first_session = create(:discovery_session, course:, starts_at: Time.zone.local(2026, 12, 22, 12))

    post admin_course_unavailability_periods_path, params: {
      course_unavailability_period: {
        starts_on: '2026-12-21',
        ends_on: '2027-01-04',
        course_ids: [course.id]
      }
    }
    confirmation_token = conflict_confirmation_token
    create(:discovery_session, course:, starts_at: Time.zone.local(2026, 12, 23, 12))

    expect do
      post admin_course_unavailability_periods_path, params: {
        course_unavailability_period: {
          starts_on: '2026-12-21',
          ends_on: '2027-01-04',
          course_ids: [course.id]
        },
        conflict_confirmation_token: confirmation_token
      }
    end.not_to change(CourseUnavailabilityPeriod, :count)

    expect(response.body).to include(first_session.course.title, '23 décembre 2026')
    expect(conflict_confirmation_token).not_to eq(confirmation_token)
  end

  it 'warns again when a conflict date changes after the warning' do
    discovery_session = create(:discovery_session, course:, starts_at: Time.zone.local(2026, 12, 22, 12))
    attributes = { starts_on: '2026-12-21', ends_on: '2027-01-04', course_ids: [course.id] }
    post admin_course_unavailability_periods_path, params: { course_unavailability_period: attributes }
    confirmation_token = conflict_confirmation_token

    discovery_session.update_with_course_locks(starts_at: Time.zone.local(2026, 12, 23, 12))

    expect do
      post admin_course_unavailability_periods_path, params: {
        course_unavailability_period: attributes,
        conflict_confirmation_token: confirmation_token
      }
    end.not_to change(CourseUnavailabilityPeriod, :count)
    expect(response.body).to include('23 décembre 2026')
    expect(conflict_confirmation_token).not_to eq(confirmation_token)
  end

  it 'creates the period when every conflict disappears after the warning' do
    discovery_session = create(:discovery_session, course:, starts_at: Time.zone.local(2026, 12, 22, 12))
    attributes = { starts_on: '2026-12-21', ends_on: '2027-01-04', course_ids: [course.id] }
    post admin_course_unavailability_periods_path, params: { course_unavailability_period: attributes }
    confirmation_token = conflict_confirmation_token

    discovery_session.update_with_course_locks(active: false)

    expect do
      post admin_course_unavailability_periods_path, params: {
        course_unavailability_period: attributes,
        conflict_confirmation_token: confirmation_token
      }
    end.to change(CourseUnavailabilityPeriod, :count).by(1)
    expect(response).to have_http_status(:see_other)
  end

  it 'warns again when a conflict course changes after the warning' do
    other_course = create(:course, :discoverable, category: course.category, title: 'Other course')
    session = create(:discovery_session, course:, starts_at: Time.zone.local(2026, 12, 22, 12))
    attributes = { starts_on: '2026-12-21', ends_on: '2027-01-04', course_ids: [course.id, other_course.id] }
    post admin_course_unavailability_periods_path, params: { course_unavailability_period: attributes }
    confirmation_token = conflict_confirmation_token

    session.update_with_course_locks(course_id: other_course.id)

    expect do
      post admin_course_unavailability_periods_path, params: {
        course_unavailability_period: attributes,
        conflict_confirmation_token: confirmation_token
      }
    end.not_to change(CourseUnavailabilityPeriod, :count)
    expect(response.body).to include('Other course')
    expect(conflict_confirmation_token).not_to eq(confirmation_token)
  end

  it 'warns again when the confirmed registration count changes after the warning' do
    session = create(:discovery_session, course:, starts_at: Time.zone.local(2026, 12, 22, 12))
    attributes = { starts_on: '2026-12-21', ends_on: '2027-01-04', course_ids: [course.id] }
    post admin_course_unavailability_periods_path, params: { course_unavailability_period: attributes }
    confirmation_token = conflict_confirmation_token

    create(:discovery_registration, discovery_session: session, status: :confirmed)

    expect do
      post admin_course_unavailability_periods_path, params: {
        course_unavailability_period: attributes,
        conflict_confirmation_token: confirmation_token
      }
    end.not_to change(CourseUnavailabilityPeriod, :count)
    expect(response.body).to include('1 inscription confirmée')
    expect(conflict_confirmation_token).not_to eq(confirmation_token)
  end

  it 'renders a fresh warning for an invalid confirmation token' do
    create(:discovery_session, course:, starts_at: Time.zone.local(2026, 12, 22, 12))

    expect do
      post admin_course_unavailability_periods_path, params: {
        course_unavailability_period: {
          starts_on: '2026-12-21',
          ends_on: '2027-01-04',
          course_ids: [course.id]
        },
        conflict_confirmation_token: 'invalid'
      }
    end.not_to change(CourseUnavailabilityPeriod, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(conflict_confirmation_token).not_to eq('invalid')
  end

  it 'warns before updating a period and preserves it until confirmation' do
    period = create(:course_unavailability_period,
                    platform:,
                    courses: [course],
                    starts_on: Date.new(2026, 12, 1),
                    ends_on: Date.new(2026, 12, 2))
    session = create(:discovery_session, course:, starts_at: Time.zone.local(2026, 12, 22, 12))
    attributes = {
      starts_on: '2026-12-21',
      ends_on: '2027-01-04',
      course_ids: [course.id]
    }

    patch admin_course_unavailability_period_path(period), params: { course_unavailability_period: attributes }

    expect(response).to have_http_status(:unprocessable_content)
    expect(period.reload).to have_attributes(starts_on: Date.new(2026, 12, 1), ends_on: Date.new(2026, 12, 2))
    confirmation_token = conflict_confirmation_token

    patch admin_course_unavailability_period_path(period), params: {
      course_unavailability_period: attributes,
      conflict_confirmation_token: confirmation_token
    }

    expect(response).to redirect_to(admin_course_unavailability_period_path(period))
    expect(period.reload).to have_attributes(starts_on: Date.new(2026, 12, 21), ends_on: Date.new(2027, 1, 4))
  end

  it 'does not accept conflict confirmation from another platform' do
    other_platform = create(:platform, name: 'Other platform')
    other_course = create(:course, title: 'Other course', category: create(:category, platform: other_platform, title: 'Other category'))
    create(:discovery_session, course: other_course, starts_at: Time.zone.local(2026, 12, 22, 12))
    session = create(:discovery_session, course:, starts_at: Time.zone.local(2026, 12, 22, 12))
    other_period = build(:course_unavailability_period,
                         platform: other_platform,
                         courses: [other_course],
                         starts_on: Date.new(2026, 12, 21),
                         ends_on: Date.new(2027, 1, 4))
    expect(other_period.save_with_course_locks).to be false

    expect do
      post admin_course_unavailability_periods_path, params: {
        course_unavailability_period: {
          starts_on: '2026-12-21',
          ends_on: '2027-01-04',
          course_ids: [course.id]
        },
        conflict_confirmation_token: other_period.conflict_confirmation_token
      }
    end.not_to change(CourseUnavailabilityPeriod, :count)

    expect(response.body).to include(session.course.title)
    expect(response.body).not_to include('Other course')
    expect(conflict_confirmation_token).not_to eq(other_period.conflict_confirmation_token)
  end
end
