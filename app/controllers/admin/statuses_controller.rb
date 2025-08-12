# frozen_string_literal: true

module Admin
  class StatusesController < BaseController
    before_action :set_subscription!

    def update
      if @subscription.update(status: status_param)
        @subscription.notify_confirmation! if @subscription.confirmed?
        redirect_back_or_to [:admin, @subscription], notice: t('.success'), status: :see_other
      else
        redirect_back_or_to [:admin, @subscription], alert: @subscription.errors.full_messages.to_sentence, status: :see_other
      end
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
