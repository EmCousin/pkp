# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('db/migrate/20260812190029_normalize_legacy_user_countries')

describe 'Password resets', type: :request do
  it 'resets the password of a user with a legacy country value' do
    user = create(:user)
    user.update_column(:country, 'France') # rubocop:disable Rails/SkipsModelValidations
    NormalizeLegacyUserCountries.new.migrate(:up)
    reset_password_token = user.send_reset_password_instructions

    put user_password_path, params: {
      user: {
        reset_password_token:,
        password: 'new-password',
        password_confirmation: 'new-password'
      }
    }

    expect(response).to have_http_status(:redirect)
    expect(user.reload).to be_valid_password('new-password')
    expect(user.country).to eq('FR')
  end
end
