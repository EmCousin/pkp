# frozen_string_literal: true

module Admin
  module Abstract
    class SubscriptionsController < ::Admin::BaseController
      protected

      def set_subscription!
        @subscription = Current.platform.subscriptions.find_by!(
          id: params.expect(:subscription_id),
          year: Subscription.current_year
        )
      end
    end
  end
end
