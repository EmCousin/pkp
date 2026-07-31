# frozen_string_literal: true

module Coach
  class DiscoverySessionsController < BaseController
    before_action :set_discovery_session, only: :show

    def index
      @discovery_sessions = DiscoverySession.active.recent.includes(:course, :subscriptions).order(:starts_at)
    end

    def show; end

    private

    def set_discovery_session
      @discovery_session = DiscoverySession.active.find(params[:id])
    end
  end
end
