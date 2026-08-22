# frozen_string_literal: true

module Dashboard
  module Abstract
    class SubscriptionsController < DashboardController
      protected

      def set_subscription!
        @subscription = current_user.subscriptions.for_platform(Current.platform).not_archived.find(params.expect(:subscription_id))
        raise ActiveRecord::RecordNotFound unless @subscription.completion_open?
      end
    end
  end
end
