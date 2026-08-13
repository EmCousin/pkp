# frozen_string_literal: true

require 'rails_helper'

describe 'Admin subscriptions', type: :request do
  include Devise::Test::IntegrationHelpers

  before { sign_in create(:user, :admin, phone_number: '+33612345679') }

  it 'includes the current list page in the destroy action' do
    course = create(:course)
    subscription = create(:subscription, courses: [course])
    create(:subscription, courses: [course])
    current_page = admin_subscriptions_path(page: 2, per_page: 1, status: :pending)

    get current_page

    form = Nokogiri::HTML(response.body).at_css("form[action='#{admin_subscription_path(subscription)}']")
    expect(form.at_css("input[name='return_to']")['value']).to eq(current_page)
  end

  it 'returns to the current list page after destroying a subscription' do
    subscription = create(:subscription, courses: [create(:course)])
    return_to = admin_subscriptions_path(page: 2, status: :pending, year: subscription.year)

    delete admin_subscription_path(subscription), params: { return_to: }

    expect(response).to redirect_to(return_to)
    expect(Subscription).not_to exist(subscription.id)
  end

  it 'returns to the subscriptions list when destroyed from its page' do
    subscription = create(:subscription, courses: [create(:course)])

    delete admin_subscription_path(subscription)

    expect(response).to redirect_to(admin_subscriptions_path)
  end
end
