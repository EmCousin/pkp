require 'rails_helper'

describe 'Discovery attendance', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:discovery_session) { create(:discovery_session) }
  let(:subscription) do
    create(
      :subscription,
      registration_type: :discovery,
      discovery_session:,
      member: create(:member),
      status: :confirmed
    )
  end

  it 'lets a coach view sessions and mark a participant present' do
    sign_in create(:user, coach: true, phone_number: '+33612345678')

    get coach_discovery_session_path(discovery_session)
    expect(response).to have_http_status(:ok)

    patch coach_discovery_session_attendance_path(discovery_session, subscription),
          params: { subscription: { attendance_status: 'present' } }

    expect(response).to redirect_to(coach_discovery_session_path(discovery_session))
    expect(subscription.reload).to be_attendance_present
  end

  it 'lets an admin manage sessions and attendance' do
    sign_in create(:user, :admin, phone_number: '+33612345678')

    get admin_discovery_session_path(discovery_session)
    expect(response).to have_http_status(:ok)

    patch admin_discovery_session_attendance_path(discovery_session, subscription),
          params: { subscription: { attendance_status: 'absent' } }

    expect(response).to redirect_to(admin_discovery_session_path(discovery_session))
    expect(subscription.reload).to be_attendance_absent

    get admin_subscription_path(subscription)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(discovery_session.course.title)
  end

  it 'prevents an admin from deleting a finalized registration' do
    sign_in create(:user, :admin, phone_number: '+33612345678')
    subscription

    expect do
      delete admin_subscription_path(subscription)
    end.not_to change(Subscription, :count)

    expect(response).to redirect_to(admin_subscriptions_path)
  end

  it 'prevents an admin from deleting a course used by a discovery session' do
    sign_in create(:user, :admin, phone_number: '+33612345678')
    course = discovery_session.course

    expect do
      delete admin_course_path(course)
    end.not_to change(Course, :count)

    expect(response).to redirect_to(admin_courses_path)
  end
end
