# frozen_string_literal: true

module Admin
  class PaymentProofsController < BaseController
    before_action :set_subscription!

    def destroy
      @subscription.payment_proof.purge
      redirect_back_or_to [:admin, @subscription], notice: t('.success'), status: :see_other
    end

    private

    def set_subscription!
      @subscription = Current.platform.subscriptions.where(paid_at: nil).find(params.expect(:subscription_id))
    end
  end
end
