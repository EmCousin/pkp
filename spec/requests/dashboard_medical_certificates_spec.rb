# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Metrics/BlockLength
describe 'Dashboard medical certificates', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:member) { create(:member, user:) }
  let(:course) { create(:course, category: create(:category)) }
  let(:file) do
    Rack::Test::UploadedFile.new(Rails.root.join('spec/support/file_examples/avatar.jpg'))
  end
  let(:subscription) do
    create(
      :subscription,
      member:,
      courses: [course],
      terms_accepted_at: Time.current,
      doctor_certified_at: Time.current,
      medical_certificate: file,
      medical_certificate_validated_at: Time.current
    )
  end

  before { sign_in user }

  describe 'PATCH update' do
    it 'requires a new admin validation after the certificate is replaced' do
      subscription.update!(paid_at: Time.current, payment_method: :cash)

      patch dashboard_subscription_medical_certificate_path(subscription), params: {
        subscription: { doctor_certified: '1', medical_certificate: file }
      }

      expect(subscription.reload.medical_certificate_validated_at).to be_nil
      expect(subscription).not_to be_confirmed
    end
  end

  describe 'DELETE destroy' do
    it "lets the member remove their own attachment when it isn't the actual certificate" do
      delete dashboard_subscription_medical_certificate_path(subscription)

      expect(response).to redirect_to(edit_dashboard_subscription_medical_certificate_path(subscription))
      expect(subscription.reload.medical_certificate).not_to be_attached
      expect(subscription.medical_certificate_validated_at).to be_nil
      expect(subscription.doctor_certified_at).to be_present
    end
  end
end
# rubocop:enable Metrics/BlockLength
