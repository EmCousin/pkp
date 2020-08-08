# frozen_string_literal: true

module Admin
  module Abstract
    class SubscriptionsController < AdminController
      protected

      def set_subscription!
        @subscription = Subscription.find_by!(
          id: params[:subscription_id],
          year: Subscription.current_year
        )
      end
    end
  end
end
