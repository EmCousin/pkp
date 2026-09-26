# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Metrics/BlockLength
describe 'Admin medical certificates', type: :request do
  include Devise::Test::IntegrationHelpers

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

  it 'lets an admin validate a medical certificate, confirming the subscription' do
    subscription.update!(paid_at: Time.current, payment_method: :cash)

    put admin_subscription_medical_certificate_path(subscription)

    expect(response).to redirect_to(admin_subscription_path(subscription))
    expect(subscription.reload.medical_certificate_validated_at).to be_present
    expect(subscription).to be_confirmed
  end

  it 'lets an admin remove an erroneous medical certificate' do
    delete admin_subscription_medical_certificate_path(subscription)

    expect(response).to redirect_to(admin_subscription_path(subscription))
    expect(subscription.reload.medical_certificate).not_to be_attached
    expect(subscription.medical_certificate_validated_at).to be_nil
  end
end
# rubocop:enable Metrics/BlockLength
