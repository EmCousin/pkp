# frozen_string_literal: true

module Admin
  class StatusesController < BaseController
    before_action :set_subscription!

    def update
      if update_status
        @subscription.notify_confirmation! if @subscription.confirmed?
        redirect_back_or_to [:admin, @subscription], notice: t('.success'), status: :see_other
      else
        redirect_back_or_to [:admin, @subscription], alert: @subscription.errors.full_messages.to_sentence, status: :see_other
      end
    end

    private

    def update_status
      return @subscription.update(status: status_param) unless @subscription.is_a?(DiscoveryRegistration)

      @subscription.update_status_with_registration_locks(status_param)
    end

    def set_subscription!
      @subscription = Current.platform.subscriptions.find(params.expect(:subscription_id))
    end

    def status_param
      subscription_params.require(:status)
    end

    def subscription_params
      params.expect(subscription: [:status])
    end
  end
end
