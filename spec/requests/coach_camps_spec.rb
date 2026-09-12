require 'rails_helper'

describe 'Coach camps', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:coach) { create(:user, coach: true, phone_number: '+33612345678') }
  let(:camp) { create(:camp) }

  before { sign_in coach }

  describe 'GET /coach/camps' do
    it 'lists active upcoming camps' do
      camp
      get coach_camps_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(camp.title)
    end

    it 'does not list inactive camps' do
      create(:camp, :inactive)
      get coach_camps_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /coach/camps/:id' do
    it 'shows camp participants with contact details' do
      camps_sub = create(:camps_subscription, camp:)
      camps_sub.subscription.update!(status: :confirmed)
      member = camps_sub.subscription.member

      get coach_camp_path(camp)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(member.first_name)
      expect(response.body).to include(member.last_name)
      expect(response.body).to include(member.email)
      expect(response.body).to include(member.phone_number)
    end

    it 'rejects non-coach users' do
      sign_out coach
      sign_in create(:user, phone_number: '+33600000001')
      get coach_camp_path(camp)
      expect(response).not_to have_http_status(:ok)
    end
  end
end
