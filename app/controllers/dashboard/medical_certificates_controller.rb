# frozen_string_literal: true

module Dashboard
  class MedicalCertificatesController < Dashboard::Abstract::SubscriptionsController
    before_action :set_subscription!

    def edit; end

    def update
      if @subscription.update(subscription_params)
        @subscription.confirm! if @subscription.completed?
        redirect_to next_completion_step_path(@subscription), status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def subscription_params
      params.expect(subscription: %i[doctor_certified medical_certificate])
    end
  end
end
