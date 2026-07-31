# frozen_string_literal: true

module Admin
  module DiscoverySessions
    class SubscriptionsController < BaseController
      before_action :set_discovery_session
      before_action :set_subscription

      def update
        @subscription.update!(attendance_params)
        redirect_to [:admin, @discovery_session], status: :see_other
      end

      private

      def set_discovery_session
        @discovery_session = DiscoverySession.find(params[:discovery_session_id])
      end

      def set_subscription
        @subscription = @discovery_session.subscriptions.confirmed.find(params[:id])
      end

      def attendance_params
        params.expect(subscription: [:attendance_status])
      end
    end
  end
end
