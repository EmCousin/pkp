# frozen_string_literal: true

require 'rails_helper'

describe 'Admin course unavailability periods', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:platform) { Platform.find_by!(domain: 'example.com') }
  let!(:course) { create(:course, category: create(:category, platform:)) }

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
    other_course = create(:course, category: create(:category, platform: other_platform, title: 'Other category'))

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

  it 'does not expose another platform period' do
    other_platform = create(:platform, name: 'Other platform')
    other_course = create(:course, category: create(:category, platform: other_platform, title: 'Other category'))
    period = create(:course_unavailability_period, platform: other_platform, courses: [other_course])

    get admin_course_unavailability_period_path(period)

    expect(response).to have_http_status(:not_found)
  end
end
