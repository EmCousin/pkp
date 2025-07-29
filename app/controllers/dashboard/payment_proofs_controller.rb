# frozen_string_literal: true

module Dashboard
  class PaymentProofsController < Dashboard::Abstract::SubscriptionsController
    before_action :set_subscription!, only: %i[edit update]

    def edit; end

    def update
      if @subscription.update(subscription_params)
        redirect_to next_completion_step_path(@subscription), status: :see_other
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def subscription_params
      params.require(:subscription).permit(:payment_proof)
    end
  end
end
