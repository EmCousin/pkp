# frozen_string_literal: true

module Admin
  class PaymentsController < BaseController
    before_action :set_subscription!

    def create
      @subscription.mark_as_paid!(payment_method: payment_method_param)
      redirect_back_or_to [:admin, @subscription], notice: t('.success'), status: :see_other
    end

    def destroy
      @subscription.mark_as_not_paid!
      redirect_back_or_to [:admin, @subscription], notice: t('.success'), status: :see_other
    end

    private

    def set_subscription!
      @subscription = Subscription.find(params[:subscription_id])
    end

    def payment_method_param
      subscription_params.require(:payment_method)
    end

    def subscription_params
      params.expect(subscription: [:payment_method])
    end
  end
end
