# frozen_string_literal: true

require 'rails_helper'

describe 'Dashboard members', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }

  before { sign_in user }

  it 'renders a retry message for an empty submission' do
    expect do
      post dashboard_members_path
    end.not_to change(Member, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('Le formulaire n&#39;a pas été reçu')
  end
end
