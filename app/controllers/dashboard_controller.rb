# frozen_string_literal: true

class DashboardController < ApplicationController
  helper_method :current_platform

  before_action :authenticate_user!

  def show; end

  private

  def current_platform
    @current_platform ||= Platform.current
  end
end
