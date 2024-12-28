# frozen_string_literal: true

module Dashboard
  class PaymentsController < Dashboard::Abstract::SubscriptionsController
    before_action :filter_enabled!
    before_action :set_subscription!, only: %i[new create]
    before_action :filter_already_paid!

    def new; end

    def create
      if @subscription.pay!(params[:stripeToken])
        redirect_to :dashboard, notice: t('.success'), status: :see_other
      else
        redirect_back fallback_location: root_path, alert: t('.error')
      end
    end

    private

    def filter_enabled!
      return false if Rails.configuration.features.online_payment[:enabled]

      redirect_to :dashboard, alert: t('defaults.forbidden')
    end

    def filter_already_paid!
      redirect_back fallback_location: root_path, alert: t('.already_paid') if @subscription.paid?
    end
  end
end
