require 'rails_helper'

describe 'Admin discovery sessions', type: :request do
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
