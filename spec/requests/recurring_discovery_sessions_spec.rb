require 'rails_helper'

describe 'Recurring discovery sessions', type: :request do
  include Devise::Test::IntegrationHelpers
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user, phone_number: '+33612345678') }
  let!(:member) { create(:member, user:) }
  let(:category) { create(:category, title: 'Adultes') }
  let!(:course) { create(:course, :discoverable, category:, title: 'Adultes samedi', weekday: :samedi) }

  before { sign_in user }

  it 'presents discoverable categories and their courses' do
    hidden_course = create(:course, category:, title: 'Cours non disponible')

    get dashboard_discovery_sessions_path
    expect(response.body).to include(category.title)

    get dashboard_discovery_sessions_path(category_id: category.id)
    expect(response.body).to include(course.title)
    expect(response.body).not_to include(hidden_course.title)
  end

  it 'only offers dates matching the selected course weekday' do
    travel_to Time.zone.local(2026, 9, 1) do
      get dashboard_discovery_sessions_path(category_id: category.id, course_id: course.id)

      options = response.parsed_body.css('select[name="occurs_on"] option').pluck('value')
      expected_dates = course.next_discovery_date.step(course.discovery_season_end, 7).map(&:iso8601)

      expect(options).to eq(expected_dates)
      expect(options.first).to eq('2026-09-12')
    end
  end

  it 'does not offer dates in an unavailable period, including both boundaries' do
    travel_to Time.zone.local(2026, 9, 1) do
      first_blocked_date = Date.new(2026, 9, 19)
      last_blocked_date = Date.new(2026, 9, 26)
      create(:course_unavailability_period,
             platform: course.platform,
             courses: [course],
             starts_on: first_blocked_date,
             ends_on: last_blocked_date)

      get dashboard_discovery_sessions_path(category_id: category.id, course_id: course.id)

      options = response.parsed_body.css('select[name="occurs_on"] option').pluck('value')
      expect(options).not_to include(first_blocked_date.iso8601, last_blocked_date.iso8601)
      expect(options).to include('2026-09-12', '2026-10-03')
    end
  end

  it 'creates an occurrence for a valid course date' do
    occurs_on = course.next_discovery_date

    expect do
      post dashboard_discovery_sessions_path, params: { course_id: course.id, occurs_on: occurs_on.iso8601 }
    end.to change(DiscoverySession, :count).by(1)

    discovery_session = DiscoverySession.last
    expect(discovery_session).to have_attributes(course:, occurs_on:, capacity: 12, price: 25)
    expect(response).to redirect_to(dashboard_discovery_session_path(discovery_session))
  end

  it 'reuses the occurrence when the same date is selected twice' do
    occurs_on = course.next_discovery_date
    existing = DiscoverySession.find_or_create_for_course!(course:, occurs_on:)

    expect do
      post dashboard_discovery_sessions_path, params: { course_id: course.id, occurs_on: occurs_on.iso8601 }
    end.not_to change(DiscoverySession, :count)

    expect(response).to redirect_to(dashboard_discovery_session_path(existing))
  end

  it 'does not reopen an inactive legacy session on the selected date' do
    occurs_on = course.next_discovery_date
    starts_at = Time.zone.local(occurs_on.year, occurs_on.month, occurs_on.day, 18)
    create(:discovery_session, course:, starts_at:, active: false)

    expect do
      post dashboard_discovery_sessions_path, params: { course_id: course.id, occurs_on: occurs_on.iso8601 }
    end.not_to change(DiscoverySession, :count)

    expect(response).to redirect_to(dashboard_discovery_sessions_path(category_id: category.id, course_id: course.id))
  end

  it 'rejects a date that does not match the course weekday' do
    invalid_date = course.next_discovery_date + 1.day

    expect do
      post dashboard_discovery_sessions_path, params: { course_id: course.id, occurs_on: invalid_date.iso8601 }
    end.not_to change(DiscoverySession, :count)

    expect(response).to redirect_to(dashboard_discovery_sessions_path(category_id: category.id, course_id: course.id))
  end

  it 'rejects a forged unavailable date' do
    occurs_on = course.next_discovery_date
    create(:course_unavailability_period,
           platform: course.platform,
           courses: [course],
           starts_on: occurs_on,
           ends_on: occurs_on)

    expect do
      post dashboard_discovery_sessions_path, params: { course_id: course.id, occurs_on: occurs_on.iso8601 }
    end.not_to change(DiscoverySession, :count)
  end

  it 'rejects registration for an existing automatic session that becomes unavailable' do
    discovery_session = DiscoverySession.find_or_create_for_course!(course:, occurs_on: course.next_discovery_date)
    create(:course_unavailability_period,
           platform: course.platform,
           courses: [course],
           starts_on: discovery_session.occurrence_date,
           ends_on: discovery_session.occurrence_date)

    expect do
      post dashboard_discovery_session_subscriptions_path(discovery_session), params: { member_id: member.id }
    end.not_to change(DiscoveryRegistration, :count)
  end

  it 'rejects registration for an existing legacy session that becomes unavailable' do
    occurs_on = course.next_discovery_date
    discovery_session = create(:discovery_session,
                               course:,
                               occurs_on: nil,
                               starts_at: Time.zone.local(occurs_on.year, occurs_on.month, occurs_on.day, 18),
                               active: true,
                               open: true)
    create(:course_unavailability_period,
           platform: course.platform,
           courses: [course],
           starts_on: occurs_on,
           ends_on: occurs_on)

    expect do
      post dashboard_discovery_session_subscriptions_path(discovery_session), params: { member_id: member.id }
    end.not_to change(DiscoveryRegistration, :count)
  end

  it 'hides an existing legacy session that becomes unavailable' do
    occurs_on = course.next_discovery_date
    discovery_session = create(:discovery_session,
                               course:,
                               occurs_on: nil,
                               starts_at: Time.zone.local(occurs_on.year, occurs_on.month, occurs_on.day, 18),
                               active: true,
                               open: true)
    create(:course_unavailability_period,
           platform: course.platform,
           courses: [course],
           starts_on: occurs_on,
           ends_on: occurs_on)

    get dashboard_discovery_sessions_path

    expect(response.body).not_to include(dashboard_discovery_session_path(discovery_session))
  end

  it 'does not change annual enrollment availability' do
    travel_to Time.zone.local(2026, 9, 1) do
      create(:pricing, category:, starts_at: Date.current, ends_at: Date.current + 1.year)
      create(:course_unavailability_period,
             platform: course.platform,
             courses: [course],
             starts_on: Date.current,
             ends_on: Date.current + 1.month)

      expect do
        post dashboard_subscriptions_path,
             params: { subscription: { member_id: member.id, category_id: category.id, course_ids: [course.id] } }
      end.to change(AnnualSubscription, :count).by(1)
    end
  end

  it 'blocks new registrations after automatic discovery is disabled' do
    discovery_session = DiscoverySession.find_or_create_for_course!(course:, occurs_on: course.next_discovery_date)
    course.update!(discovery_enabled: false)

    expect do
      post dashboard_discovery_session_subscriptions_path(discovery_session), params: { member_id: member.id }
    end.not_to change(DiscoveryRegistration, :count)

    expect(response).to redirect_to(dashboard_discovery_session_path(discovery_session))
  end

  it 'continues through the existing participant registration flow' do
    post dashboard_discovery_sessions_path, params: { course_id: course.id, occurs_on: course.next_discovery_date.iso8601 }
    discovery_session = DiscoverySession.last

    expect do
      post dashboard_discovery_session_subscriptions_path(discovery_session), params: { member_id: member.id }
    end.to change(DiscoveryRegistration, :count).by(1)

    expect(DiscoveryRegistration.last.fee).to eq(course.discovery_price)
  end

  it 'keeps generated occurrences editable by an administrator without changing their date' do
    discovery_session = DiscoverySession.find_or_create_for_course!(course:, occurs_on: course.next_discovery_date)
    sign_in create(:user, :admin, phone_number: '+33612345679')

    get edit_admin_discovery_session_path(discovery_session)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('calendrier automatique')
  end
end
