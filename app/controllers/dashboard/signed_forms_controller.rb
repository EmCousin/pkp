# frozen_string_literal: true

module Dashboard
  class SignedFormsController < Dashboard::Abstract::SubscriptionsController
    before_action :filter_enabled!
    before_action :set_subscription!, only: %i[edit update]

    def edit; end

    def update
      if @subscription.update(subscription_params)
        redirect_to dashboard_index_path, notice: t('.success')
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def filter_enabled!
      return false if Rails.configuration.features.signed_form[:enabled]

      redirect_to dashboard_index_path, alert: t('defaults.forbidden')
    end

    def subscription_params
      params.require(:subscription).permit(:signed_form)
    end
  end
end
