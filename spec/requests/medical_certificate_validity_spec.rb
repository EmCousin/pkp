# frozen_string_literal: true

require 'rails_helper'

describe 'Medical certificate validity', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:platform) do
    Platform.current.tap { |current_platform| current_platform.update!(medical_certificate_validity_seasons: 3) }
  end
  let(:user) { create(:user) }
  let(:member) { create(:member, user:, platform:) }
  let(:category) { create(:category, title: 'Adulte', platform:) }
  let(:course) { create(:course, category:) }
  let(:current_year) { Subscription.current_year }
  let(:subscription) { create(:subscription, member:, courses: [course], year: current_year) }
  let(:file) do
    Rack::Test::UploadedFile.new(
      Rails.root.join('spec/support/file_examples/avatar.jpg')
    )
  end

  before { sign_in user }

  it 'skips the upload step when a certificate from two seasons earlier is valid' do
    create(
      :subscription,
      member:,
      courses: [course],
      year: current_year - 2,
      doctor_certified_at: Time.current,
      medical_certificate: file
    )

    patch dashboard_subscription_terms_path(subscription), params: { subscription: { terms_accepted: '1' } }

    expect(response).to redirect_to(new_dashboard_subscription_payment_path(subscription))
  end

  it 'requests a new upload when the previous certificate has expired' do
    create(
      :subscription,
      member:,
      courses: [course],
      year: current_year - 3,
      doctor_certified_at: Time.current,
      medical_certificate: file
    )

    patch dashboard_subscription_terms_path(subscription), params: { subscription: { terms_accepted: '1' } }

    expect(response).to redirect_to(edit_dashboard_subscription_medical_certificate_path(subscription))
  end
end
