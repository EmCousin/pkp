# frozen_string_literal: true

require 'rails_helper'

describe 'Admin discovery sessions', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:course) { create(:course, :discoverable, weekday: :samedi) }

  before { sign_in create(:user, :admin, phone_number: '+33612345679') }

  it 'creates a custom discovery session' do
    custom_date = course.next_discovery_date.tomorrow
    starts_at = Time.zone.local(custom_date.year, custom_date.month, custom_date.day, 18)

    get admin_discovery_sessions_path
    expect(response.body).to include(new_admin_discovery_session_path)

    get new_admin_discovery_session_path
    expect(response.body).to include('discovery_session[starts_at]')

    expect do
      post admin_discovery_sessions_path, params: {
        discovery_session: {
          course_id: course.id,
          starts_at: starts_at.iso8601,
          capacity: 6,
          price: 20,
          active: '1',
          open: '1'
        }
      }
    end.to change(DiscoverySession, :count).by(1)

    expect(DiscoverySession.last).to have_attributes(course:, starts_at:, occurs_on: nil, capacity: 6, price: 20)
    expect(response).to redirect_to(admin_discovery_session_path(DiscoverySession.last))
  end

  it 'rejects a custom session on an unavailable date' do
    custom_date = course.next_discovery_date.tomorrow
    create(:course_unavailability_period, platform: course.platform, courses: [course], starts_on: custom_date, ends_on: custom_date)

    expect do
      post admin_discovery_sessions_path, params: {
        discovery_session: {
          course_id: course.id,
          starts_at: custom_date.in_time_zone.iso8601,
          capacity: 6,
          price: 20,
          active: '1',
          open: '1'
        }
      }
    end.not_to change(DiscoverySession, :count)

    expect(response).to have_http_status(:unprocessable_content)
  end

  it 'explains an unavailable date in English' do
    custom_date = course.next_discovery_date.tomorrow
    create(:course_unavailability_period, platform: course.platform, courses: [course], starts_on: custom_date, ends_on: custom_date)

    I18n.with_locale(:en) do
      post admin_discovery_sessions_path, params: {
        discovery_session: {
          course_id: course.id,
          starts_at: custom_date.in_time_zone.iso8601,
          capacity: 6,
          price: 20,
          active: '1',
          open: '1'
        }
      }
    end

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.text).to include('Starts at is not available for this course')
  end

  it 'rejects activating a custom session on an unavailable date' do
    custom_date = course.next_discovery_date.tomorrow
    session = create(:discovery_session, course:, starts_at: custom_date.in_time_zone, active: false)
    create(:course_unavailability_period, platform: course.platform, courses: [course], starts_on: custom_date, ends_on: custom_date)

    patch admin_discovery_session_path(session), params: {
      discovery_session: {
        course_id: course.id,
        starts_at: session.starts_at.iso8601,
        capacity: session.capacity,
        price: session.price,
        active: '1',
        open: '1'
      }
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(session.reload).not_to be_active
  end

  it 'rejects moving a custom session to a blocked course and date' do
    session = create(:discovery_session, course:)
    original_starts_at = session.starts_at
    target_course = create(:course, :discoverable, category: course.category, weekday: :dimanche)
    target_date = target_course.next_discovery_date
    create(:course_unavailability_period,
           platform: course.platform,
           courses: [target_course],
           starts_on: target_date,
           ends_on: target_date)

    patch admin_discovery_session_path(session), params: {
      discovery_session: {
        course_id: target_course.id,
        starts_at: target_date.in_time_zone.iso8601,
        capacity: session.capacity,
        price: session.price,
        active: '1',
        open: '1'
      }
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(session.reload).to have_attributes(course:, starts_at: original_starts_at)
  end

  it 'searches automatic and custom sessions by date' do
    occurs_on = course.next_discovery_date
    automatic = DiscoverySession.find_or_create_for_course!(course:, occurs_on:)
    custom_course = create(:course, category: course.category, title: 'Cours ponctuel')
    custom = create(:discovery_session, course: custom_course,
                                        starts_at: Time.zone.local(occurs_on.year, occurs_on.month, occurs_on.day, 18))
    other = create(:discovery_session, course: custom_course, starts_at: occurs_on.tomorrow.in_time_zone)

    get admin_discovery_sessions_path(date: occurs_on.iso8601)

    expect(response.body).to include(admin_discovery_session_path(automatic), admin_discovery_session_path(custom))
    expect(response.body).not_to include(admin_discovery_session_path(other))
  end

  it 'paginates discovery sessions' do
    26.times do |index|
      create(:discovery_session, course:, starts_at: (index + 30).days.from_now)
    end

    get admin_discovery_sessions_path

    expect(response.body).to include('page=2')
  end
end
