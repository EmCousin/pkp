# frozen_string_literal: true

module Admin
  class StatusesController < BaseController
    before_action :set_subscription!

    def update
      @subscription.update!(status: status_param)
      redirect_back_or_to [:admin, @subscription], notice: t('.success'), status: :see_other
    end

    private

    def set_subscription!
      @subscription = Subscription.find(params[:subscription_id])
    end

    def status_param
      subscription_params.require(:status)
    end

    def subscription_params
      params.expect(subscription: [:status])
    end
  end
end
