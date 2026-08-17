# frozen_string_literal: true

module Dashboard
  class CampsController < DashboardController
    def index
      @camps = current_platform.camps.available.order(:starts_at, :created_at).includes(:subscriptions)
    end

    def show
      @camp = current_platform.camps.available.find_by(id: params[:id])
      redirect_to dashboard_camps_path, notice: t('.unavailable') unless @camp
    end
  end
end
