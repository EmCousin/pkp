# frozen_string_literal: true

module Dashboard
  class PaymentsController < Dashboard::Abstract::SubscriptionsController
    before_action :set_subscription!, only: %i[new create]
    before_action :filter_already_paid!

    def new; end

    def create
      if @subscription.pay_with_stripe!(params.require(:stripeToken))
        @subscription.confirmed! if @subscription.completed?
        redirect_to next_completion_step_path(@subscription), status: :see_other, notice: t('.success')
      else
        redirect_back fallback_location: root_path, alert: t('.error')
      end
    end

    private

    def filter_already_paid!
      redirect_back fallback_location: root_path, alert: t('.already_paid') if @subscription.paid?
    end
  end
end
