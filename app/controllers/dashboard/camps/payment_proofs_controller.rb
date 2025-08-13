# frozen_string_literal: true

module Dashboard
  module Camps
    class PaymentProofsController < DashboardController
      before_action :set_camp
      before_action :set_subscription
      before_action :filter_already_paid!

      def edit; end

      def update
        if @subscription.update(payment_proof_params)
          redirect_to [:dashboard, @camp], notice: t('.success'), status: :see_other
        else
          redirect_back_or_to [:edit, :dashboard, @camp, @subscription, :payment_proof], alert: @subscription.errors.full_messages.to_sentence,
                                                                                         status: :unprocessable_content
        end
      end

      private

      def set_camp
        @camp = Camp.available.find(params[:camp_id])
      end

      def set_subscription
        @subscription = current_user.subscriptions.find(params[:subscription_id])
      end

      def payment_proof_params
        params.expect(subscription: [:payment_proof])
      end

      def filter_already_paid!
        redirect_to [:dashboard, @camp], alert: t('.already_paid_for', member: @subscription.member.full_name), status: :see_other if @subscription.paid?
      end
    end
  end
end
