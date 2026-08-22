# frozen_string_literal: true

module Dashboard
  class CampsController < DashboardController
    def index
      @camps = Current.platform.camps.available.order(:starts_at, :created_at).includes(:subscriptions)
    end

    def show
      @camp = Current.platform.camps.available.find_by(id: params[:id])
      if @camp
        @members = current_user.members.active.where(platform: Current.platform).includes(subscriptions: :camps_subscription)
      else
        redirect_to dashboard_camps_path, notice: t('.unavailable')
      end
    end
  end
end
