# frozen_string_literal: true

module Dashboard
  class MedicalCertificatesController < Dashboard::Abstract::SubscriptionsController
    before_action :set_subscription!

    def edit; end

    def update
      @subscription.medical_certificate_validated_at = nil

      if @subscription.update(subscription_params)
        @subscription.confirm! if @subscription.completed?
        redirect_to next_completion_step_path(@subscription), status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @subscription.confirmed?
        return redirect_to edit_dashboard_subscription_medical_certificate_path(@subscription), alert: t('.confirmed'), status: :see_other
      end

      medical_certificate = Subscriptions::MedicalCertificate.new(subscription: @subscription)
      if medical_certificate.source_in_use?
        return redirect_to edit_dashboard_subscription_medical_certificate_path(@subscription), alert: t('.in_use'), status: :see_other
      end

      @subscription.medical_certificate.purge
      @subscription.update!(medical_certificate_validated_at: nil)
      redirect_to edit_dashboard_subscription_medical_certificate_path(@subscription), notice: t('.success'), status: :see_other
    end

    private

    def subscription_params
      params.expect(subscription: %i[doctor_certified medical_certificate])
    end
  end
end
