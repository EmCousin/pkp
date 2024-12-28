# frozen_string_literal: true

module Dashboard
  class MedicalCertificatesController < Dashboard::Abstract::SubscriptionsController
    before_action :filter_enabled!
    before_action :set_subscription!, only: %i[edit update]

    def edit; end

    def update
      if @subscription.update(subscription_params)
        redirect_to :dashboard, notice: t('.success')
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def filter_enabled!
      return false if Rails.configuration.features.medical_certificate[:enabled]

      redirect_to :dashboard, alert: t('defaults.forbidden')
    end

    def subscription_params
      params.require(:subscription).permit(:medical_certificate)
    end
  end
end
