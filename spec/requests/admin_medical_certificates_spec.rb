# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Metrics/BlockLength
describe 'Admin medical certificates', type: :request do
  let(:file) do
    Rack::Test::UploadedFile.new(Rails.root.join('spec/support/file_examples/avatar.jpg'))
  end
  let(:subscription) do
    create(
      :subscription,
      courses: [create(:course)],
      terms_accepted_at: Time.current,
      doctor_certified_at: Time.current,
      medical_certificate: file
    )
  end

  before { sign_in create(:user, :admin, phone_number: '+33612345679') }

  describe 'PUT update' do
    it 'lets an admin validate a medical certificate, confirming the subscription' do
      subscription.update!(paid_at: Time.current, payment_method: :cash)

      put admin_subscription_medical_certificate_path(subscription)

      expect(response).to redirect_to(admin_subscription_path(subscription))
      expect(subscription.reload.medical_certificate_validated_at).to be_present
      expect(subscription).to be_confirmed
    end

    it 'validates the prior season subscription that an inherited certificate actually comes from' do
      member = create(:member)
      course = create(:course)
      previous_subscription = create(
        :subscription,
        member:,
        courses: [course],
        year: Subscription.current_year - 1,
        doctor_certified_at: Time.current,
        medical_certificate: file
      )
      current_subscription = create(
        :subscription,
        member:,
        courses: [course],
        year: Subscription.current_year,
        terms_accepted_at: Time.current,
        paid_at: Time.current,
        payment_method: :cash
      )

      get admin_subscription_path(current_subscription)
      expect(response.body).to include(
        I18n.t('admin.subscriptions.show.medical_certificate_pending_validation_from_season', season: previous_subscription.season)
      )

      put admin_subscription_medical_certificate_path(current_subscription)

      expect(response).to redirect_to(admin_subscription_path(current_subscription))
      expect(previous_subscription.reload.medical_certificate_validated_at).to be_present
      expect(current_subscription.reload.medical_certificate_validated_at).to be_nil
      expect(current_subscription).to be_completed
      expect(current_subscription).to be_confirmed
    end

    it 'redirects with an alert instead of raising when there is no certificate to validate' do
      subscription.update!(doctor_certified_at: nil)
      subscription.medical_certificate.purge

      put admin_subscription_medical_certificate_path(subscription)

      expect(response).to redirect_to(admin_subscription_path(subscription))
      expect(subscription.reload.medical_certificate_validated_at).to be_nil
      expect(subscription).not_to be_confirmed
    end
  end

  describe 'DELETE destroy' do
    it 'lets an admin remove an erroneous medical certificate' do
      delete admin_subscription_medical_certificate_path(subscription)

      expect(response).to redirect_to(admin_subscription_path(subscription))
      expect(subscription.reload.medical_certificate).not_to be_attached
      expect(subscription.medical_certificate_validated_at).to be_nil
    end

    it 'refuses to purge a certificate that a later season subscription relies on' do
      member = create(:member)
      course = create(:course)
      source_subscription = create(
        :subscription,
        member:,
        courses: [course],
        year: Subscription.current_year,
        terms_accepted_at: Time.current,
        doctor_certified_at: Time.current,
        medical_certificate: file,
        medical_certificate_validated_at: Time.current
      )
      source_subscription.update!(paid_at: Time.current, payment_method: :cash)
      later_subscription = create(
        :subscription,
        member:,
        courses: [course],
        year: Subscription.current_year + 1,
        terms_accepted_at: Time.current
      )
      later_subscription.update!(paid_at: Time.current, payment_method: :cash)
      expect(later_subscription).to be_completed

      delete admin_subscription_medical_certificate_path(source_subscription)

      expect(response).to redirect_to(admin_subscription_path(source_subscription))
      expect(source_subscription.reload.medical_certificate).to be_attached
      expect(later_subscription.reload).to be_completed
    end

    it 'refuses to remove the certificate from an already confirmed subscription' do
      subscription.update!(paid_at: Time.current, payment_method: :cash, medical_certificate_validated_at: Time.current)
      subscription.confirm!

      delete admin_subscription_medical_certificate_path(subscription)

      expect(response).to redirect_to(admin_subscription_path(subscription))
      expect(subscription.reload.medical_certificate).to be_attached
      expect(subscription.medical_certificate_validated_at).to be_present
    end
  end
end
# rubocop:enable Metrics/BlockLength
