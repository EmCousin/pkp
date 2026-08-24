# frozen_string_literal: true

require 'rails_helper'

describe 'Admin subscriptions', type: :request do
  include Devise::Test::IntegrationHelpers

  before { sign_in create(:user, :admin, phone_number: '+33612345679') }

  it 'uses a Turbo Stream destroy action from the subscriptions list' do
    subscription = create(:subscription, courses: [create(:course)])

    get admin_subscriptions_path

    destroy_path = admin_subscription_path(subscription, format: :turbo_stream)
    form = Nokogiri::HTML(response.body).at_css("form[action='#{destroy_path}']")
    expect(form).to be_present
  end

  it 'removes the subscription row after destroying from the list' do
    subscription = create(:subscription, courses: [create(:course)])

    delete admin_subscription_path(subscription, format: :turbo_stream)

    expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
    expect(response.body).to include(%(action="remove" target="row_subscription_#{subscription.id}"))
    expect(Subscription).not_to exist(subscription.id)
  end

  it 'returns to the subscriptions list when destroyed from its page' do
    subscription = create(:subscription, courses: [create(:course)])
    destroy_path = admin_subscription_path(subscription, format: :html)

    get admin_subscription_path(subscription)

    forms = Nokogiri::HTML(response.body).css("form[action='#{destroy_path}']")
    expect(forms.size).to eq(2)

    delete destroy_path

    expect(response).to redirect_to(admin_subscriptions_path)
  end

  it 'validates a subscription submitted for another platform' do
    other_platform = create(:platform)
    other_member = create(:member, platform: other_platform)
    category = create(:category, platform: other_platform, title: 'Other adults')
    course = create(:course, category:)

    expect do
      post admin_subscriptions_path, params: {
        subscription: { member_id: other_member.id, course_ids: [course.id] }
      }
    end.not_to change(Subscription, :count)

    expect(response).to have_http_status(:unprocessable_content)
  end

  it 'lets an admin change the course of an invoiced subscription' do
    category = create(:category)
    initial_course = create(:course, category:, weekday: :lundi)
    replacement_course = create(:course, category:, weekday: :mardi)
    subscription = create(:subscription, courses: [initial_course], paid_at: Time.current)
    invoice = subscription.billing_invoice

    get edit_admin_subscription_path(subscription)
    expect(response).to have_http_status(:ok)

    patch admin_subscription_path(subscription), params: {
      subscription: {
        member_id: subscription.member_id,
        course_ids: [replacement_course.id]
      }
    }

    expect(response).to redirect_to(admin_subscription_path(subscription, updated: true))
    expect(subscription.reload.courses).to contain_exactly(replacement_course)
    expect(subscription.billing_invoice).to eq(invoice)
  end
end
