require 'rails_helper'

describe 'External event registrations', type: :request do
  include Devise::Test::IntegrationHelpers
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user, phone_number: '+33612345678') }
  let!(:member) { create(:member, user:) }

  before { sign_in user }

  describe 'camp registration' do
    let(:camp) { create(:camp, price: 90, external_price: 140, open_to_externals: true) }

    it 'creates a standalone registration at the external rate' do
      expect do
        post dashboard_camp_subscriptions_path(camp), params: { member_id: member.id }
        expect(response).to have_http_status(:see_other)
      end.to change(Subscription.registration_type_camp, :count).by(1)

      subscription = Subscription.registration_type_camp.last
      expect(subscription.parent_subscription).to be_nil
      expect(subscription.fee).to eq(140)
      expect(response).to redirect_to(edit_dashboard_subscription_terms_path(subscription))
    end

    it 'keeps the internal rate and annual parent for an annual student' do
      annual_subscription = create(
        :subscription,
        member:,
        courses: [create(:course)],
        status: :confirmed,
        year: camp.year,
        terms_accepted_at: Time.current
      )

      post dashboard_camp_subscriptions_path(camp), params: { member_id: member.id }

      subscription = Subscription.registration_type_camp.last
      expect(subscription.parent_subscription).to eq(annual_subscription)
      expect(subscription.fee).to eq(90)
      expect(response).to redirect_to(new_dashboard_subscription_payment_path(subscription))
    end

    it 'does not allow a paid registration to be deleted' do
      post dashboard_camp_subscriptions_path(camp), params: { member_id: member.id }
      subscription = Subscription.registration_type_camp.last
      subscription.update!(paid_at: Time.current)

      expect do
        delete dashboard_camp_subscription_path(camp, subscription)
      end.not_to change(Subscription, :count)

      expect(response).to redirect_to(dashboard_camp_path(camp))
    end
  end

  describe 'discovery registration' do
    let(:discovery_session) { create(:discovery_session, price: 25) }

    it 'creates a payable registration without blocking annual enrollment' do
      post dashboard_discovery_session_subscriptions_path(discovery_session), params: { member_id: member.id }

      subscription = Subscription.registration_type_discovery.last
      expect(subscription.fee).to eq(25)
      expect(response).to redirect_to(edit_dashboard_subscription_terms_path(subscription))
      expect(member).to be_in(Member.available(discovery_session.year))
    end

    it 'then creates an annual registration for the same member' do
      travel_to Time.zone.local(Time.current.year, 9, 1) do
        post dashboard_discovery_session_subscriptions_path(discovery_session), params: { member_id: member.id }
        course = discovery_session.course

        expect do
          post dashboard_subscriptions_path,
               params: { subscription: { member_id: member.id, category_id: course.category_id, course_ids: [course.id] } }
        end.to change(Subscription.registration_type_annual, :count).by(1)

        annual_subscription = Subscription.registration_type_annual.last
        expect(annual_subscription.member).to eq(member)
        expect(response).to redirect_to(edit_dashboard_subscription_terms_path(annual_subscription))
      end
    end
  end

  describe 'event pages' do
    it 'renders camps and discovery sessions for a user without annual enrollment' do
      camp = create(:camp, open_to_externals: true)
      discovery_session = create(:discovery_session)

      get dashboard_camp_path(camp)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(member.full_name)

      get dashboard_discovery_session_path(discovery_session)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(member.full_name)
    end

    it 'keeps an existing registration visible when the event is full or closed' do
      discovery_session = create(:discovery_session, capacity: 1)
      subscription = create(:subscription, member:, registration_type: :discovery, discovery_session:)
      discovery_session.update!(open: false)

      get dashboard_discovery_session_path(discovery_session)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(member.full_name)
      expect(response.body).to include(edit_dashboard_subscription_terms_path(subscription))
    end

    it 'lists standalone event registrations on the dashboard' do
      discovery_session = create(:discovery_session)
      create(:subscription, member:, registration_type: :discovery, discovery_session:)

      get dashboard_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(discovery_session.course.title)
      expect(response.body).to include('Finaliser l&#39;inscription')
    end
  end

  it 'does not delete an account containing a finalized event registration' do
    discovery_session = create(:discovery_session)
    create(:subscription, member:, registration_type: :discovery, discovery_session:, status: :confirmed)

    expect do
      delete user_registration_path
    end.not_to change(User, :count)

    expect(response).to redirect_to(edit_user_registration_path)
  end
end
