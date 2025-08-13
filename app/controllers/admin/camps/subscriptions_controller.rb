# frozen_string_literal: true

module Admin
  module Camps
    class SubscriptionsController < BaseController
      before_action :set_camp
      before_action :set_parent_subscription, only: %i[create]
      before_action :set_subscription, only: %i[destroy]

      def create
        @subscription = @parent_subscription.build_child_subscription(
          camps_subscription_attributes: { camp_id: @camp.id }
        )

        if @subscription.save
          redirect_to [:admin, @camp], notice: t('.success'), status: :see_other
        else
          redirect_to [:admin, @camp], alert: @subscription.errors.full_messages.to_sentence, status: :unprocessable_content
        end
      end

      def destroy
        if @subscription.destroy
          redirect_to [:admin, @camp], notice: t('.success'), status: :see_other
        else
          redirect_to [:admin, @camp], alert: t('.error'), status: :unprocessable_content
        end
      end

      private

      def set_camp
        @camp = Camp.find(params.require(:camp_id))
      end

      def set_parent_subscription
        @parent_subscription = Subscription.find(params.require(:subscription_id))
      end

      def set_subscription
        @subscription = Subscription.find(params.require(:subscription_id))
      end
    end
  end
end
