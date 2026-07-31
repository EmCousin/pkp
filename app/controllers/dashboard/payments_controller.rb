# frozen_string_literal: true

module Dashboard
  class PaymentsController < Dashboard::Abstract::SubscriptionsController
    before_action :set_subscription!, only: :new
    before_action :set_subscription_for_payment_return!, only: :show
    before_action :filter_already_paid!, only: %i[new]

    def show
      return if @subscription.paid?

      @subscription.verify_stripe_payment!(
        payment_intent_id: params[:payment_intent],
        payment_intent_client_secret: params[:payment_intent_client_secret],
        redirect_status: params[:redirect_status]
      )
    end

    def new
      @payment_intent = @subscription.stripe_payment_intent
      redirect_to dashboard_path, alert: t('.payment_already_submitted'), status: :see_other unless @payment_intent
    end

    private

    def set_subscription_for_payment_return!
      @subscription = current_user.subscriptions.find(params[:subscription_id])
    end

    def filter_already_paid!
      redirect_back_or_to(root_path, alert: t('.already_paid')) if @subscription.paid?
    end
  end
end
