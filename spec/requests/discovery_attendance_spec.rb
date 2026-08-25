require 'rails_helper'

describe 'Discovery attendance', type: :request do
  let(:discovery_session) { create(:discovery_session) }
  let(:subscription) do
    create(
      :discovery_registration,
      discovery_session:,
      member: create(:member),
      status: :confirmed
    )
  end

  it 'lets a coach view sessions and mark a participant present' do
    sign_in create(:user, coach: true, phone_number: '+33612345678')

    get coach_discovery_session_path(discovery_session)
    expect(response).to have_http_status(:ok)

    patch coach_discovery_session_subscription_path(discovery_session, subscription),
          params: { subscription: { attendance_status: 'present' } }

    expect(response).to redirect_to(coach_discovery_session_path(discovery_session))
    expect(subscription.reload).to be_attendance_present
  end

  it 'lets an admin manage sessions and attendance' do
    sign_in create(:user, :admin, phone_number: '+33612345678')
    subscription

    get admin_discovery_session_path(discovery_session)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Non renseigné', 'Excusé·e')

    patch admin_discovery_session_subscription_path(discovery_session, subscription),
          params: { subscription: { attendance_status: 'absent' } }

    expect(response).to redirect_to(admin_discovery_session_path(discovery_session))
    expect(subscription.reload).to be_attendance_absent

    get admin_subscription_path(subscription)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(discovery_session.course.title)
  end

  it 'does not update a registration through another discovery session' do
    sign_in create(:user, :admin, phone_number: '+33612345678')
    other_session = create(:discovery_session, course: discovery_session.course, starts_at: 2.weeks.from_now)

    patch admin_discovery_session_subscription_path(other_session, subscription),
          params: { subscription: { attendance_status: 'present' } }

    expect(response).to have_http_status(:not_found)
    expect(subscription.reload.attendance_status).to be_nil
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

  it 'prevents an admin from editing an event registration through the generic form' do
    sign_in create(:user, :admin, phone_number: '+33612345678')
    other_member = create(:member)

    patch admin_subscription_path(subscription), params: { subscription: { member_id: other_member.id } }

    expect(response).to redirect_to(admin_subscription_path(subscription))
    expect(subscription.reload.member).not_to eq(other_member)
  end

  it 'does not turn an existing annual subscription into a camp registration' do
    sign_in create(:user, :admin, phone_number: '+33612345678')
    annual_subscription = create(:subscription, courses: [create(:course)])
    camp = create(:camp, open_to_externals: true)

    expect do
      patch admin_subscription_path(annual_subscription),
            params: { subscription: { camps_subscription_attributes: { camp_id: camp.id } } }
    end.not_to change(CampsSubscription, :count)

    expect(annual_subscription.reload).to be_a(AnnualSubscription)
  end
end
