# frozen_string_literal: true

require 'rails_helper'

describe 'Admin platform settings', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:platform) { Platform.find_by!(domain: 'example.com') }

  before { sign_in create(:user, :admin, phone_number: '+33612345679') }

  it 'updates the medical certificate validity period' do
    patch admin_platform_path, params: {
      platform: { medical_certificate_validity_seasons: 4 }
    }

    expect(response).to redirect_to(edit_admin_platform_path)
    expect(platform.reload.medical_certificate_validity_seasons).to eq(4)
  end

  it 'allows a coach to update the settings' do
    sign_out :user
    sign_in create(:user, coach: true)

    patch admin_platform_path, params: {
      platform: { medical_certificate_validity_seasons: 2 }
    }

    expect(response).to redirect_to(edit_admin_platform_path)
    expect(platform.reload.medical_certificate_validity_seasons).to eq(2)
  end

  it 'rejects an invalid validity period' do
    patch admin_platform_path, params: {
      platform: { medical_certificate_validity_seasons: 0 }
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(platform.reload.medical_certificate_validity_seasons).to eq(3)
  end
end
