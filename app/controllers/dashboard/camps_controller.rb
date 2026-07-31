# frozen_string_literal: true

module Dashboard
  class CampsController < DashboardController
    def index
      @camps = Camp.available.order(:starts_at, :created_at).includes(:subscriptions)
    end

    def show
      @camp = Camp.available.find(params[:id])
      @members = current_user.members.includes(:subscriptions)
    end
  end
end
