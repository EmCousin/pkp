# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Metrics/BlockLength
describe 'Current platform', type: :request do
  let(:platform) { Platform.find_by!(domain: 'example.com') }

  it 'resolves the platform from the request domain' do
    sign_in create(:user, :admin, phone_number: '+33612345679')

    patch admin_platform_path, params: {
      platform: { medical_certificate_validity_seasons: 4 }
    }

    expect(response).to redirect_to(edit_admin_platform_path)
    expect(platform.reload.medical_certificate_validity_seasons).to eq(4)
  end

  it 'normalizes the request domain case' do
    host! 'WWW.EXAMPLE.COM'

    get legal_mentions_path

    expect(response).to have_http_status(:ok)
  end

  it 'switches platforms between requests' do
    other_platform = create(:platform, domain: 'other.test')
    sign_in create(:user, :admin, phone_number: '+33612345679')

    patch admin_platform_path, params: { platform: { medical_certificate_validity_seasons: 4 } }
    host! 'other.test'
    sign_in create(:user, :admin, phone_number: '+33612345680')
    patch admin_platform_path, params: { platform: { medical_certificate_validity_seasons: 2 } }

    expect(platform.reload.medical_certificate_validity_seasons).to eq(4)
    expect(other_platform.reload.medical_certificate_validity_seasons).to eq(2)
  end

  it 'rejects an unknown domain without creating a platform' do
    host! 'unknown.test'

    get legal_mentions_path

    expect(response).to have_http_status(:not_found)
    expect(Platform.find_by(domain: 'unknown.test')).to be_nil
  end

  it 'rejects contact confirmation on an unknown domain' do
    contact = create(:contact, confirmed_at: nil)
    host! 'unknown.test'

    get contact_confirmation_path(contact_id: contact.signed_id(purpose: :confirmation))

    expect(response).to have_http_status(:not_found)
    expect(contact.reload.confirmed_at).to be_nil
  end
end
# rubocop:enable Metrics/BlockLength
