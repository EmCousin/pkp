# frozen_string_literal: true

module Dashboard
  module Camps
    class SubscriptionsController < DashboardController
      before_action :set_camp
      before_action :set_parent_subscription, only: [:create]
      before_action :set_subscription, only: [:destroy]

      def create
        @subscription = @parent_subscription.build_child_subscription(
          camps_subscription_attributes: { camp_id: @camp.id }
        )

        if @subscription.save
          redirect_to [:edit, :dashboard, @camp, @subscription, :payment_proof], status: :see_other
        else
          redirect_back_to [:dashboard, @camp], alert: @subscription.errors.full_messages.to_sentence
        end
      end

      def destroy
        if @subscription.destroy
          redirect_back_or_to [:dashboard, @camp], notice: t('.success'), status: :see_other
        else
          redirect_back_or_to [:dashboard, @camp], alert: t('.error'), status: :unprocessable_entity
        end
      end

      private

      def set_parent_subscription
        @parent_subscription = current_user.subscriptions.confirmed.find(params.require(:subscription_id))
      end

      def set_camp
        @camp = Camp.available.find(params[:camp_id])
      end

      def set_subscription
        @subscription = current_user.subscriptions.find(params[:id])
      end
    end
  end
end
