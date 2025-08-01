# frozen_string_literal: true

module Dashboard
  module Camps
    class SubscriptionsController < DashboardController
      before_action :set_camp
      before_action :set_subscription, only: [:destroy]

      def create
        parent_subscription = current_user.subscriptions.confirmed.find(params[:subscription_id])

        # Create a new subscription for the camp
        @subscription = parent_subscription.child_subscriptions.new(
          member: parent_subscription.member,
          year: parent_subscription.year,
          terms_accepted_at: parent_subscription.terms_accepted_at,
          doctor_certified_at: parent_subscription.doctor_certified_at,
          camps_subscription_attributes: { camp_id: @camp.id }
        )

        if @subscription.save
          redirect_to [:edit, :dashboard, @camp, @subscription, :payment_proof], notice: t('.success'), status: :see_other
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

      def set_camp
        @camp = Camp.available.find(params[:camp_id])
      end

      def set_subscription
        @subscription = current_user.subscriptions.find(params[:id])
      end
    end
  end
end
