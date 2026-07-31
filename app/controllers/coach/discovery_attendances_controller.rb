# frozen_string_literal: true

module Coach
  class DiscoveryAttendancesController < BaseController
    def update
      discovery_session = DiscoverySession.active.find(params[:discovery_session_id])
      subscription = discovery_session.subscriptions.confirmed.find(params[:id])
      subscription.update!(attendance_params)
      redirect_to [:coach, discovery_session], status: :see_other
    end

    private

    def attendance_params
      params.expect(subscription: [:attendance_status])
    end
  end
end
