# frozen_string_literal: true

module Admin
  class DiscoverySessionTransfersController < BaseController
    before_action :set_subscription

    def new
      @discovery_session_transfer = DiscoverySessionTransfer.new(subscription: @subscription)
    end

    def create
      @discovery_session_transfer = DiscoverySessionTransfer.new(subscription: @subscription, **transfer_params)
      if @discovery_session_transfer.perform
        redirect_to [:admin, @subscription], notice: t('.success'), status: :see_other
      else
        render :new, status: :unprocessable_content
      end
    end

    private

    def set_subscription
      @subscription = Current.platform.subscriptions
                             .where(type: DiscoveryRegistration.sti_name)
                             .find(params.expect(:subscription_id))
    end

    def transfer_params
      params.expect(discovery_session_transfer: [:occurs_on]).to_h.symbolize_keys
    end
  end
end
