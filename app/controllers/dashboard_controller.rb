# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    @subscriptions = annual_subscriptions
    @event_subscriptions = event_subscriptions
  end

  private

  def annual_subscriptions
    current_user.subscriptions.registration_type_annual
                .not_archived
                .where(year: Subscription.current_year, parent_subscription_id: nil)
                .includes(:member, :child_subscriptions)
                .with_attached_medical_certificate
  end

  def event_subscriptions
    current_user.subscriptions.not_archived
                .where(parent_subscription_id: nil, registration_type: %i[camp discovery])
                .includes(:camp, :discovery_session, :member)
                .order(created_at: :desc)
  end
end
