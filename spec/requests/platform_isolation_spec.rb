# frozen_string_literal: true

require 'rails_helper'

describe 'Platform isolation', type: :request do
  include ActiveSupport::Testing::TimeHelpers
  include Devise::Test::IntegrationHelpers

  it 'does not use another platform availability for the current platform' do
    platform = Platform.find_by!(domain: 'example.com')
    user = create(:user, phone_number: '+33612345678')
    create(:member, user:, platform:)
    other_platform = create(:platform, name: 'Other platform')
    other_category = create(:category, platform: other_platform, title: 'Other category')
    create(:course, category: other_category, active: true, capacity: 10)
    sign_in user

    travel_to Time.zone.local(2026, 9, 1) do
      get new_dashboard_subscription_path
    end

    expect(response).to redirect_to(dashboard_capacity_path)
  end
end
