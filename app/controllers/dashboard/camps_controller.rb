# frozen_string_literal: true

module Dashboard
  class CampsController < DashboardController
    def index
      @camps = Camp.available.includes(:subscriptions)
    end

    def show
      @camp = Camp.available.find(params[:id])
    end
  end
end
