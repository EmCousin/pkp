# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    @subscriptions = current_user.subscriptions
                                 .where(year: Subscription.current_year)
                                 .where(parent_subscription_id: nil)
                                 .includes(:member, :child_subscriptions)
  end
end
