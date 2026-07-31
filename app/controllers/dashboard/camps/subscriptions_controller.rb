# frozen_string_literal: true

module Dashboard
  module Camps
    class SubscriptionsController < DashboardController
      before_action :set_camp
      before_action :set_member, only: [:create]
      before_action :set_subscription, only: [:destroy]
      before_action :check_cancellable, only: [:destroy]
      before_action :check_open_status, only: [:create]

      def create
        @subscription = build_subscription

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

      def build_subscription
        attributes = {
          registration_type: :camp,
          camps_subscription_attributes: { camp_id: @camp.id }
        }
        parent = @member.annual_subscription_for(@camp.year)

        parent ? parent.build_child_subscription(attributes) : @member.subscriptions.new(attributes.merge(year: @camp.year))
      end

      def set_member
        @member = current_user.members.find(params.require(:member_id))
      end

      def set_camp
        @camp = Camp.available.find(params[:camp_id])
      end

      def set_subscription
        @subscription = @camp.subscriptions.merge(current_user.subscriptions).find(params[:id])
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
