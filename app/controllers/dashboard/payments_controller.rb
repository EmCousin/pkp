# frozen_string_literal: true

module Dashboard
  class PaymentsController < DashboardController
    before_action :set_subscription!, only: %i[new create]

    def new; end

    def create
      if PaySubscriptionService.new(@subscription, params[:stripeToken]).perform
        redirect_to dashboard_index_path, notice: t('.payment_success')
      else
        redirect_back fallback_location: root_path, alert: t('.payment_error')
      end
    end

    private

    def set_subscription!
      @subscription = current_user.subscriptions.find_by!(
        id: params[:subscription_id],
        year: Time.now.year
      )

      redirect_back fallback_location: root_path, alert: t('.already_paid') if @subscription.paid?
    end
  end
end
