# frozen_string_literal: true

module Dashboard
  class MedicalCertificatesController < Dashboard::Abstract::SubscriptionsController
    before_action :set_subscription!
    before_action :filter_already_certified!

    def edit; end

    def update
      if @subscription.update(subscription_params)
        redirect_to next_completion_step_path(@subscription), status: :see_other
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def subscription_params
      params.require(:subscription).permit(:medical_certificate)
    end

    def filter_already_certified!
      redirect_to :dashboard, alert: t('.already_certified') if @subscription.doctor_certified_at?
    end
  end
end
