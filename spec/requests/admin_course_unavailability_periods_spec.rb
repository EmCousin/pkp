# frozen_string_literal: true

require 'rails_helper'

describe 'Admin course unavailability periods', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:platform) { Platform.find_by!(domain: 'example.com') }
  let!(:course) { create(:course, :discoverable, category: create(:category, platform:)) }

  before { sign_in create(:user, :admin, phone_number: '+33612345679') }

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
    session = create(:discovery_session, course:, starts_at: Time.zone.local(2026, 12, 22, 12))
    create_list(:discovery_registration, 2, discovery_session: session, status: :confirmed)
    create(:discovery_registration, discovery_session: session, status: :pending)

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

    edit_link = Nokogiri::HTML(response.body).xpath('//a').find { |link| link.text.include?('Modifier la période') }
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
        confirm_conflicts: '1',
        confirmed_conflict_ids: [session.id]
      }
    end.to change(CourseUnavailabilityPeriod, :count).by(1)
  end

  it 'warns again when a conflicting session appears after the create warning' do
    first_session = create(:discovery_session, course:, starts_at: Time.zone.local(2026, 12, 22, 12))
    new_session = create(:discovery_session, course:, starts_at: Time.zone.local(2026, 12, 23, 12))

    expect do
      post admin_course_unavailability_periods_path, params: {
        course_unavailability_period: {
          starts_on: '2026-12-21',
          ends_on: '2027-01-04',
          course_ids: [course.id]
        },
        confirm_conflicts: '1',
        confirmed_conflict_ids: [first_session.id]
      }
    end.not_to change(CourseUnavailabilityPeriod, :count)

    expect(response.body).to include(first_session.course.title)
    expect(response.body).to include("value=\"#{new_session.id}\"")
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

    patch admin_course_unavailability_period_path(period), params: {
      course_unavailability_period: attributes,
      confirm_conflicts: '1',
      confirmed_conflict_ids: [session.id]
    }

    expect(response).to redirect_to(admin_course_unavailability_period_path(period))
    expect(period.reload).to have_attributes(starts_on: Date.new(2026, 12, 21), ends_on: Date.new(2027, 1, 4))
  end

  it 'does not accept conflict confirmation from another platform' do
    other_platform = create(:platform, name: 'Other platform')
    other_course = create(:course, title: 'Other course', category: create(:category, platform: other_platform, title: 'Other category'))
    other_session = create(:discovery_session, course: other_course, starts_at: Time.zone.local(2026, 12, 22, 12))
    session = create(:discovery_session, course:, starts_at: Time.zone.local(2026, 12, 22, 12))

    expect do
      post admin_course_unavailability_periods_path, params: {
        course_unavailability_period: {
          starts_on: '2026-12-21',
          ends_on: '2027-01-04',
          course_ids: [course.id]
        },
        confirm_conflicts: '1',
        confirmed_conflict_ids: [other_session.id]
      }
    end.not_to change(CourseUnavailabilityPeriod, :count)

    expect(response.body).to include("value=\"#{session.id}\"")
    expect(response.body).not_to include('Other course')
  end
end
