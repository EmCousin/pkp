# frozen_string_literal: true

require 'rails_helper'

describe 'Dashboard members', type: :request do
  include Devise::Test::IntegrationHelpers
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user, phone_number: '+33612345678') }
  let!(:member) { create(:member, user:, first_name: 'Clarence', last_name: 'Asselin') }

  before { sign_in user }

  it 'lists only the current account members and links them from the navigation' do
    create(:member, first_name: 'Other account')

    get dashboard_members_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Mes membres', member.full_name)
    expect(response.body).not_to include('Other Account')
  end

  it 'shows and updates an owned member' do
    get dashboard_member_path(member)
    expect(response.body).to include(member.full_name, 'Contact d&#39;urgence', 'Zone de danger')

    patch dashboard_member_path(member), params: {
      member: member.attributes.slice(
        'first_name', 'last_name', 'birthdate', 'contact_name', 'contact_phone_number',
        'contact_relationship', 'agreed_to_advertising_right'
      ).merge(first_name: 'Mika')
    }

    expect(response).to redirect_to(dashboard_member_path(member))
    expect(member.reload.first_name).to eq('Mika')
  end

  it 'does not expose a member belonging to another account' do
    other_member = create(:member)

    get dashboard_member_path(other_member)

    expect(response).to have_http_status(:not_found)
  end

  it 'does not offer a member from another platform for annual registration' do
    create(:course)
    other_platform = create(:platform, name: 'Other platform', domain: 'other.example.com')
    other_member = create(:member, user:, platform: other_platform, first_name: 'Other platform child')

    travel_to Time.zone.local(Subscription.current_year, 9, 1, 9) do
      get new_dashboard_subscription_path
    end

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(member.full_name)
    expect(response.body).not_to include(other_member.full_name)
  end

  it 'deletes a member without protected registrations' do
    create(:subscription, member:, courses: [create(:course)])

    expect { delete dashboard_member_path(member) }
      .to change(Member, :count).by(-1)
      .and change(Subscription, :count).by(-1)

    expect(response).to redirect_to(dashboard_members_path)
  end

  it 'tombstones a member with a finalized registration' do
    registration = create(
      :discovery_registration,
      member:,
      discovery_session: create(:discovery_session),
      status: :confirmed
    )

    expect { delete dashboard_member_path(member) }.not_to change(Member, :count)

    expect(response).to redirect_to(dashboard_members_path)
    expect(member.reload).to be_tombstoned_at
    expect(registration.reload).to be_persisted
    expect(user.members).not_to include(member)
  end

  it 'returns to an event after creating another member' do
    camp = create(:camp, open_to_externals: true)

    post dashboard_members_path, params: {
      return_to: dashboard_camp_path(camp),
      member: attributes_for(:member, :minor).merge(
        avatar: Rack::Test::UploadedFile.new(Rails.root.join('spec/support/file_examples/avatar.jpg'))
      )
    }

    expect(response).to redirect_to(dashboard_camp_path(camp))
    expect(response).to have_http_status(:see_other)
    expect(user.members.count).to eq(2)
  end

  it 'does not follow an external return URL' do
    post dashboard_members_path, params: {
      return_to: 'https://example.net/phishing',
      member: attributes_for(:member, :minor).merge(
        avatar: Rack::Test::UploadedFile.new(Rails.root.join('spec/support/file_examples/avatar.jpg'))
      )
    }

    created_member = user.members.order(:id).last
    expect(response).to redirect_to(new_dashboard_subscription_path(member_id: created_member.id))
  end
end
