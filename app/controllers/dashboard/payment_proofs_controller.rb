# frozen_string_literal: true

module Dashboard
  class PaymentProofsController < Dashboard::Abstract::SubscriptionsController
    before_action :set_subscription!, only: %i[edit update]

    def edit; end

    def update
      updated = @subscription.with_lock do
        @subscription.cancel_open_stripe_payment_intent && @subscription.update(subscription_params)
      end

      if updated
        redirect_to next_completion_step_path(@subscription), notice: t('.success'), status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def subscription_params
      params.expect(subscription: [:payment_proof])
    end
  end
end
