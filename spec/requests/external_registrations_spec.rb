require 'rails_helper'

describe 'External event registrations', type: :request do
  include Devise::Test::IntegrationHelpers
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user, phone_number: '+33612345678') }
  let!(:member) { create(:member, user:) }

  before { sign_in user }

  describe 'camp registration' do
    let(:camp) { create(:camp, price: 90, external_price: 140, open: false, open_to_externals: true) }

    it 'creates a standalone registration at the external rate when open only to externals' do
      expect do
        post dashboard_camp_registrations_path(camp), params: { member_id: member.id }
        expect(response).to have_http_status(:see_other)
      end.to change(CampRegistration, :count).by(1)

      subscription = CampRegistration.last
      expect(subscription.parent_subscription).to be_nil
      expect(subscription.fee).to eq(140)
      expect(response).to redirect_to(edit_dashboard_subscription_terms_path(subscription))
    end

    it 'does not expose or accept a camp from another platform' do
      other_platform = create(:platform, name: 'Other platform')
      other_camp = create(:camp, platform: other_platform, open_to_externals: true)

      get dashboard_camps_path
      expect(response.body).not_to include(other_camp.title)

      expect do
        post dashboard_camp_registrations_path(other_camp), params: { member_id: member.id }
      end.not_to change(CampRegistration, :count)
      expect(response).to have_http_status(:not_found)
    end

    it 'keeps the internal rate and annual parent for an annual student' do
      camp.update!(open: true)
      annual_subscription = create(
        :subscription,
        member:,
        courses: [create(:course)],
        status: :confirmed,
        year: camp.year,
        terms_accepted_at: Time.current
      )

      post dashboard_camp_subscriptions_path(camp), params: { subscription_id: annual_subscription.id }

      subscription = CampRegistration.last
      expect(subscription.parent_subscription).to eq(annual_subscription)
      expect(subscription.fee).to eq(90)
      expect(response).to redirect_to(new_dashboard_subscription_payment_path(subscription))
    end

    it 'keeps internal registration closed when open only to externals' do
      annual_subscription = create(
        :subscription,
        member:,
        courses: [create(:course)],
        status: :confirmed,
        year: camp.year
      )

      expect do
        post dashboard_camp_subscriptions_path(camp), params: { subscription_id: annual_subscription.id }
      end.not_to change(CampRegistration, :count)

      expect(response).to redirect_to(dashboard_camp_path(camp))
    end

    it 'keeps standalone registration unavailable to an annual student' do
      create(:subscription, member:, courses: [create(:course)], status: :confirmed, year: camp.year)

      expect do
        post dashboard_camp_registrations_path(camp), params: { member_id: member.id }
      end.not_to change(CampRegistration, :count)

      expect(response).to have_http_status(:not_found)
    end

    it 'keeps standalone registration unavailable while annual enrollment is pending' do
      create(:subscription, member:, courses: [create(:course)], status: :pending, year: camp.year)

      expect do
        post dashboard_camp_registrations_path(camp), params: { member_id: member.id }
      end.not_to change(CampRegistration, :count)

      expect(response).to have_http_status(:not_found)
    end

    it 'requires an annual subscription on the internal endpoint' do
      expect do
        post dashboard_camp_subscriptions_path(camp), params: { subscription_id: 0 }
      end.not_to change(CampRegistration, :count)

      expect(response).to have_http_status(:not_found)
    end

    it 'does not allow a paid registration to be deleted' do
      post dashboard_camp_registrations_path(camp), params: { member_id: member.id }
      subscription = CampRegistration.last
      subscription.update!(paid_at: Time.current)

      expect do
        delete dashboard_camp_registration_path(camp, subscription)
      end.not_to change(Subscription, :count)

      expect(response).to redirect_to(dashboard_camp_path(camp))
    end

    it 'cancels an abandoned Stripe checkout when deleting a registration' do
      post dashboard_camp_registrations_path(camp), params: { member_id: member.id }
      subscription = CampRegistration.last
      subscription.update_column(:stripe_payment_intent_id, 'pi_test_123')
      camp.update_columns(active: false, starts_at: 1.day.ago, ends_at: 1.day.ago)
      allow(Stripe::PaymentIntent).to receive(:retrieve).with('pi_test_123').and_return(OpenStruct.new(status: 'requires_payment_method'))
      allow(Stripe::PaymentIntent).to receive(:cancel).with('pi_test_123')

      expect do
        delete dashboard_camp_registration_path(camp, subscription)
      end.to change(Subscription, :count).by(-1)

      expect(Stripe::PaymentIntent).to have_received(:cancel).with('pi_test_123')
    end

    it 'keeps cancellation available for an internal registration after the camp closes' do
      camp.update!(open: true)
      annual_subscription = create(
        :subscription,
        member:,
        courses: [create(:course)],
        status: :confirmed,
        year: camp.year
      )
      subscription = annual_subscription.build_child_subscription(camps_subscription_attributes: { camp_id: camp.id })
      subscription.save!
      camp.update_columns(active: false, starts_at: 1.day.ago, ends_at: 1.day.ago)

      get dashboard_path

      expect(response.body).to include(dashboard_camp_subscription_path(camp, subscription))
    end
  end

  describe 'discovery registration' do
    let(:discovery_session) { create(:discovery_session, price: 25) }

    it 'creates a payable registration without blocking annual enrollment' do
      post dashboard_discovery_session_subscriptions_path(discovery_session), params: { member_id: member.id }

      subscription = DiscoveryRegistration.last
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
        end.to change(AnnualSubscription, :count).by(1)

        annual_subscription = AnnualSubscription.last
        expect(annual_subscription.member).to eq(member)
        expect(response).to redirect_to(edit_dashboard_subscription_terms_path(annual_subscription))
      end
    end

    it 'records a Stripe payment that returns after the session starts' do
      subscription = create(
        :discovery_registration,
        member:,
        discovery_session:,
        terms_accepted_at: Time.current
      )
      subscription.update_column(:stripe_payment_intent_id, 'pi_test_123')
      discovery_session.update_column(:starts_at, 1.minute.ago)
      intent = OpenStruct.new(
        id: 'pi_test_123',
        client_secret: 'pi_test_123_secret',
        latest_charge: 'ch_test_123',
        status: 'succeeded',
        currency: 'eur',
        amount_received: subscription.fee_cents
      )
      charge = OpenStruct.new(
        id: 'ch_test_123',
        paid: true,
        amount_refunded: 0,
        currency: 'eur',
        amount: subscription.fee_cents,
        created: Time.current.to_i
      )
      allow(Stripe::PaymentIntent).to receive(:retrieve).with('pi_test_123').and_return(intent)
      allow(Stripe::Charge).to receive(:retrieve).with('ch_test_123').and_return(charge)

      get dashboard_subscription_payment_path(
        subscription,
        payment_intent: 'pi_test_123',
        payment_intent_client_secret: 'pi_test_123_secret',
        redirect_status: 'succeeded'
      )

      expect(response).to have_http_status(:ok)
      expect(subscription.reload).to be_paid
      expect(subscription).to be_confirmed
    end

    it 'records a late Stripe payment without reopening an archived registration' do
      subscription = create(
        :discovery_registration,
        member:,
        discovery_session:,
        terms_accepted_at: Time.current,
        status: :archived
      )
      subscription.update_column(:stripe_payment_intent_id, 'pi_test_123')
      intent = OpenStruct.new(
        id: 'pi_test_123',
        client_secret: 'pi_test_123_secret',
        latest_charge: 'ch_test_123',
        status: 'succeeded',
        currency: 'eur',
        amount_received: subscription.fee_cents
      )
      charge = OpenStruct.new(
        id: 'ch_test_123',
        paid: true,
        amount_refunded: 0,
        currency: 'eur',
        amount: subscription.fee_cents,
        created: Time.current.to_i
      )
      allow(Stripe::PaymentIntent).to receive(:retrieve).with('pi_test_123').and_return(intent)
      allow(Stripe::Charge).to receive(:retrieve).with('ch_test_123').and_return(charge)

      get dashboard_subscription_payment_path(
        subscription,
        payment_intent: 'pi_test_123',
        payment_intent_client_secret: 'pi_test_123_secret',
        redirect_status: 'succeeded'
      )

      expect(subscription.reload).to be_paid
      expect(subscription).to be_archived
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

    it 'shows an external user only camps visible to externals' do
      student_camp = create(:camp, title: 'Stage élèves', active: true, visible_to_externals: false)
      external_camp = create(:camp, title: 'Stage externes', active: false, visible_to_externals: true)
      everyone_camp = create(:camp, title: 'Stage pour tous', active: true, visible_to_externals: true)
      hidden_camp = create(:camp, title: 'Stage masqué', active: false, visible_to_externals: false)

      get dashboard_camps_path

      expect(response.body).to include(external_camp.title, everyone_camp.title)
      expect(response.body).not_to include(student_camp.title, hidden_camp.title)
    end

    it 'shows an annual student only camps visible to students' do
      student_camp = create(:camp, title: 'Stage élèves', active: true, visible_to_externals: false)
      external_camp = create(:camp, title: 'Stage externes', active: false, visible_to_externals: true)
      everyone_camp = create(:camp, title: 'Stage pour tous', active: true, visible_to_externals: true)
      create(:subscription, member:, courses: [create(:course)], status: :confirmed, year: student_camp.year)

      get dashboard_camps_path

      expect(response.body).to include(student_camp.title, everyone_camp.title)
      expect(response.body).not_to include(external_camp.title)
    end

    it 'redirects direct links to camps hidden from the user audience' do
      student_camp = create(:camp, active: true, visible_to_externals: false)

      get dashboard_camp_path(student_camp)

      expect(response).to redirect_to(dashboard_camps_path)
    end

    it 'keeps the camp detail accessible to an existing registrant after its audience changes' do
      camp = create(:camp, open_to_externals: true, visible_to_externals: true)
      create(:camp_registration, member:, year: camp.year, camps_subscription_attributes: { camp_id: camp.id })
      camp.update!(active: true, visible_to_externals: false)

      get dashboard_camp_path(camp)

      expect(response).to have_http_status(:ok)
    end

    it 'rejects direct registrations to camps hidden from the member audience' do
      student_camp = create(:camp, active: true, visible_to_externals: false, open_to_externals: true)

      expect do
        post dashboard_camp_registrations_path(student_camp), params: { member_id: member.id }
      end.not_to change(CampRegistration, :count)

      expect(response).to have_http_status(:not_found)
    end

    it 'redirects stale camp links to the available camps' do
      camp = create(:camp, active: false)

      get dashboard_camp_path(camp)

      expect(response).to redirect_to(dashboard_camps_path)
      expect(flash[:notice]).to eq("Ce stage n'est plus disponible.")
    end

    it 'keeps an existing registration visible when the event is full or closed' do
      discovery_session = create(:discovery_session, capacity: 1)
      subscription = create(:discovery_registration, member:, discovery_session:)
      discovery_session.update!(open: false)

      get dashboard_discovery_session_path(discovery_session)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(member.full_name)
      expect(response.body).to include(edit_dashboard_subscription_terms_path(subscription))
    end

    it 'lists standalone event registrations on the dashboard' do
      discovery_session = create(:discovery_session)
      create(:discovery_registration, member:, discovery_session:)

      get dashboard_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(discovery_session.course.title)
      expect(response.body).to include('Finaliser l&#39;inscription')
    end

    it 'does not render a resume link for an archived registration' do
      discovery_session = create(:discovery_session)
      subscription = create(:discovery_registration, member:, discovery_session:, status: :archived)

      get dashboard_discovery_session_path(discovery_session)

      expect(response.body).not_to include(edit_dashboard_subscription_terms_path(subscription))
    end

    it 'offers to add another member when nobody can register for a camp' do
      camp = create(:camp, open_to_externals: true)
      create(:camp_registration, member:, camps_subscription_attributes: { camp_id: camp.id })

      get dashboard_camp_path(camp)

      add_member_path = new_dashboard_member_path(return_to: dashboard_camp_path(camp))
      expect(response.body).to include(CGI.escapeHTML(add_member_path), 'Ajouter un participant')
    end

    it 'offers to add another member when nobody is eligible for a discovery session' do
      adult_category = create(:category, min_age: 18, max_age: 100)
      discovery_session = create(:discovery_session, course: create(:course, category: adult_category))
      member.update_column(:birthdate, 10.years.ago)

      get dashboard_discovery_session_path(discovery_session)

      add_member_path = new_dashboard_member_path(return_to: dashboard_discovery_session_path(discovery_session))
      expect(response.body).to include(CGI.escapeHTML(add_member_path), 'Ajouter un participant')
    end
  end

  it 'does not delete an account containing a finalized event registration' do
    discovery_session = create(:discovery_session)
    create(:discovery_registration, member:, discovery_session:, status: :confirmed)

    expect do
      delete user_registration_path
    end.not_to change(User, :count)

    expect(response).to redirect_to(edit_user_registration_path)
  end
end
