# frozen_string_literal: true

require 'rails_helper'

describe 'Admin payment proofs', type: :request do
  include Devise::Test::IntegrationHelpers

  before { sign_in create(:user, :admin, phone_number: '+33612345679') }

  it 'lets an admin remove an erroneous payment proof' do
    subscription = create(:subscription, courses: [create(:course)])
    subscription.payment_proof.attach(
      io: Rails.root.join('spec/support/file_examples/avatar.jpg').open,
      filename: 'certificate.jpg'
    )

    get admin_subscription_path(subscription)
    expect(response.body).to include(admin_subscription_payment_proof_path(subscription))

    delete admin_subscription_payment_proof_path(subscription)

    expect(response).to redirect_to(admin_subscription_path(subscription))
    expect(subscription.reload.payment_proof).not_to be_attached
  end
end
