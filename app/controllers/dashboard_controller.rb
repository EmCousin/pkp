# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @subscription = current_user.subscriptions.find_by(year: Time.current.year)
  end
end
