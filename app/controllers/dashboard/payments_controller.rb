# frozen_string_literal: true

module Dashboard
  class PaymentsController < Dashboard::Abstract::SubscriptionsController
    before_action :set_subscription!, only: %i[show new create]
    before_action :filter_already_paid!, only: %i[new create]

    def show
      return if @subscription.paid?

      @subscription.verify_stripe_payment!(
        payment_intent_id: params[:payment_intent],
        payment_intent_client_secret: params[:payment_intent_client_secret],
        redirect_status: params[:redirect_status]
      )
    end

    def new; end

    def create
      if @subscription.pay_with_stripe!(params.require(:stripeToken))
        @subscription.confirm! if @subscription.completed?
        redirect_to next_completion_step_path(@subscription), status: :see_other, notice: t('.success')
      else
        redirect_back fallback_location: root_path, alert: t('.error')
      end
    rescue Stripe::CardError => e
      Rollbar.error(e)
      redirect_back fallback_location: root_path, alert: e.message
    end

    private

    def filter_already_paid!
      redirect_back fallback_location: root_path, alert: t('.already_paid') if @subscription.paid?
    end
  end
end
