# frozen_string_literal: true

module Dashboard
  class DiscoverySessionsController < DashboardController
    def index
      @discovery_sessions = DiscoverySession.available.includes(:course, :subscriptions).order(:starts_at)
    end

    def show
      @discovery_session = DiscoverySession.available.find(params[:id])
      @members = current_user.members.includes(:subscriptions)
    end
  end
end
