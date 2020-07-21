# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @subscriptions = current_user.subscriptions.where(year: Subscription.current_year)
  end
end
