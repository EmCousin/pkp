# frozen_string_literal: true

module Dashboard
  module Abstract
    class SubscriptionsController < DashboardController
      protected

      def set_subscription!
        @subscription = current_user.subscriptions.find_by!(
          id: params[:subscription_id],
          year: Subscription.current_year
        )
      end
    end
  end
end
