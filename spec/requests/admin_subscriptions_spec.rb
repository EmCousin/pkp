# frozen_string_literal: true

require 'rails_helper'

describe 'Admin subscriptions', type: :request do
  include Devise::Test::IntegrationHelpers
  include ActiveSupport::Testing::TimeHelpers

  before { sign_in create(:user, :admin, phone_number: '+33612345679') }

  it 'uses a Turbo Stream destroy action from the subscriptions list' do
    subscription = create(:subscription, courses: [create(:course)])

    get admin_subscriptions_path

    destroy_path = admin_subscription_path(subscription, format: :turbo_stream)
    form = Nokogiri::HTML(response.body).at_css("form[action='#{destroy_path}']")
    expect(form).to be_present
  end

  it 'removes the subscription row after destroying from the list' do
    subscription = create(:subscription, courses: [create(:course)])

    delete admin_subscription_path(subscription, format: :turbo_stream)

    expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
    expect(response.body).to include(%(action="remove" target="row_subscription_#{subscription.id}"))
    expect(Subscription).not_to exist(subscription.id)
  end

  it 'returns to the subscriptions list when destroyed from its page' do
    subscription = create(:subscription, courses: [create(:course)])
    destroy_path = admin_subscription_path(subscription, format: :html)

    get admin_subscription_path(subscription)

    forms = Nokogiri::HTML(response.body).css("form[action='#{destroy_path}']")
    expect(forms.size).to eq(2)

    delete destroy_path

    expect(response).to redirect_to(admin_subscriptions_path)
  end

  it 'validates a subscription submitted for another platform' do
    other_platform = create(:platform)
    other_member = create(:member, platform: other_platform)
    category = create(:category, platform: other_platform, title: 'Other adults')
    course = create(:course, category:)

    expect do
      post admin_subscriptions_path, params: {
        subscription: { member_id: other_member.id, course_ids: [course.id] }
      }
    end.not_to change(Subscription, :count)

    expect(response).to have_http_status(:unprocessable_content)
  end

  it 'lets an admin add a course without regenerating the invoice' do
    category = create(:category)
    create(:pricing, category:, prices: [280, 420])
    initial_course = create(:course, category:, weekday: :lundi)
    additional_course = create(:course, category:, weekday: :mardi)
    subscription = create(:subscription, courses: [initial_course], paid_at: Time.current)
    invoice = subscription.billing_invoice
    invoiced_fee = subscription.fee

    get edit_admin_subscription_path(subscription)
    expect(response).to have_http_status(:ok)

    expect do
      patch admin_subscription_path(subscription), params: {
        subscription: {
          member_id: subscription.member_id,
          course_ids: [initial_course.id, additional_course.id]
        }
      }
    end.not_to have_enqueued_job(Pennylane::CreateInvoiceJob)

    expect(response).to redirect_to(admin_subscription_path(subscription, updated: true))
    expect(subscription.reload.courses).to contain_exactly(initial_course, additional_course)
    expect(subscription.fee).to eq(invoiced_fee)
    expect(subscription.billing_invoice).to eq(invoice)
    expect(Billing::Invoice.where(invoiceable: subscription)).to contain_exactly(invoice)
  end

  describe 'transferring a discovery registration' do
    around { |example| travel_to(Time.zone.local(2026, 9, 1)) { example.run } }

    let(:course) { create(:course, :discoverable, weekday: :samedi, title: 'Adultes samedi') }
    let(:source_date) { course.next_discovery_date }
    let(:target_date) { source_date + 1.week }
    let(:source_session) { DiscoverySession.find_or_create_for_course!(course:, occurs_on: source_date) }
    let(:registration) do
      create(:discovery_registration, discovery_session: source_session, paid_at: Time.current, attendance_status: :present)
    end

    it 'offers the other dates for the same course' do
      get admin_subscription_path(registration)

      expect(response.body).to include(new_admin_subscription_discovery_session_transfer_path(registration))

      get new_admin_subscription_discovery_session_transfer_path(registration)

      options = response.parsed_body.css('select[name="discovery_session_transfer[occurs_on]"] option').pluck('value')
      expect(options).to include(target_date.iso8601)
      expect(options).not_to include(source_date.iso8601)
    end

    it 'moves a paid registration without changing its payment, price, or invoice' do
      original_fee = registration.fee
      original_paid_at = registration.paid_at
      original_invoice = registration.billing_invoice
      expect(original_invoice).to be_present

      post admin_subscription_discovery_session_transfer_path(registration), params: {
        discovery_session_transfer: { occurs_on: target_date.iso8601 }
      }

      target_session = DiscoverySession.find_by!(course:, occurs_on: target_date)
      expect(response).to redirect_to(admin_subscription_path(registration))
      expect(registration.reload).to have_attributes(
        discovery_session: target_session,
        fee: original_fee,
        paid_at: original_paid_at,
        billing_invoice: original_invoice,
        attendance_status: nil
      )
    end

    it 'does not move the registration to a full session' do
      target_session = DiscoverySession.find_or_create_for_course!(course:, occurs_on: target_date)
      target_session.update!(capacity: 1)
      create(:discovery_registration, discovery_session: target_session)

      get new_admin_subscription_discovery_session_transfer_path(registration)
      options = response.parsed_body.css('select[name="discovery_session_transfer[occurs_on]"] option').pluck('value')
      expect(options).not_to include(target_date.iso8601)

      post admin_subscription_discovery_session_transfer_path(registration), params: {
        discovery_session_transfer: { occurs_on: target_date.iso8601 }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(registration.reload.discovery_session).to eq(source_session)
      expect(response.body).to include('plus disponible')
    end

    it 'rejects a date outside the course schedule' do
      invalid_date = target_date + 1.day
      registration

      expect do
        post admin_subscription_discovery_session_transfer_path(registration), params: {
          discovery_session_transfer: { occurs_on: invalid_date.iso8601 }
        }
      end.not_to change(DiscoverySession, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(registration.reload.discovery_session).to eq(source_session)
    end
  end
end
