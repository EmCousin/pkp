# frozen_string_literal: true

module Dashboard
  module Abstract
    class SubscriptionsController < DashboardController
      protected

      def set_subscription!
        @subscription = current_user.subscriptions.not_archived.find(params[:subscription_id])
        raise ActiveRecord::RecordNotFound unless @subscription.completion_open?
      end
    end
  end
end
