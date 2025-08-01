# frozen_string_literal: true

module Admin
  module Camps
    class SubscriptionsController < BaseController
      before_action :set_camp

                        def create
        parent_subscription = Subscription.find(params[:subscription_id])

        # Create a new subscription for the camp
        @subscription = Subscription.new(
          member: parent_subscription.member,
          year: parent_subscription.year,
          parent_subscription: parent_subscription,
          status: :confirmed
        )

        if @subscription.save
          @camps_subscription = CampsSubscription.create(camp: @camp, subscription: @subscription)
          @subscription.save! # Re-save to compute the fee based on the camp
          redirect_to admin_camp_path(@camp), notice: t('.success'), status: :see_other
        else
          redirect_to admin_camp_path(@camp), alert: @subscription.errors.full_messages.join(', '), status: :unprocessable_entity
        end
      end

            def destroy
        @subscription = Subscription.find(params[:id])

        if @subscription.destroy
          redirect_to admin_camp_path(@camp), notice: t('.success'), status: :see_other
        else
          redirect_to admin_camp_path(@camp), alert: t('.error'), status: :unprocessable_entity
        end
      end

      private

      def set_camp
        @camp = Camp.find(params[:camp_id])
      end
    end
  end
end
