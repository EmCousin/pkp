# frozen_string_literal: true

module Dashboard
  module Camps
    class SubscriptionsController < DashboardController
      before_action :set_available_camp, only: :create
      before_action :set_parent_subscription, only: :create
      before_action :set_subscription, only: [:destroy]
      before_action :check_cancellable, only: [:destroy]
      before_action :check_open_status, only: [:create]

      def create
        @subscription = @parent_subscription.build_child_subscription(
          camps_subscription_attributes: { camp_id: @camp.id }
        )

        if @camp.with_lock { @subscription.save }
          redirect_to next_completion_step_path(@subscription), status: :see_other
        else
          redirect_back_or_to [:dashboard, @camp], alert: @subscription.errors.full_messages.to_sentence
        end
      end

      def destroy
        if @subscription.destroy
          redirect_back_or_to [:dashboard, @camp], notice: t('.success'), status: :see_other
        else
          redirect_back_or_to [:dashboard, @camp], alert: t('.error'), status: :unprocessable_content
        end
      end

      private

      def set_parent_subscription
        @parent_subscription = current_user.subscriptions
                                           .where(registration_kind: AnnualSubscription.sti_name)
                                           .confirmed
                                           .where(year: @camp.year, parent_subscription_id: nil)
                                           .find(params.require(:subscription_id))
      end

      def set_available_camp
        @camp = Camp.available.find(params[:camp_id])
      end

      def set_subscription
        @subscription = current_user.subscriptions
                                    .where(registration_kind: CampRegistration.sti_name)
                                    .where.not(parent_subscription_id: nil)
                                    .joins(:camp)
                                    .find_by!(id: params[:id], camps: { id: params[:camp_id] })
        @camp = @subscription.camp
      end

      def check_open_status
        redirect_to [:dashboard, @camp], alert: t('.closed') unless @camp.open?
      end

      def check_cancellable
        redirect_to [:dashboard, @camp], alert: t('.already_confirmed') unless @subscription.cancellable?
      end
    end
  end
end
