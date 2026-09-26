# frozen_string_literal: true

module Admin
  class MedicalCertificatesController < BaseController
    before_action :set_subscription!

    def update
      @subscription.update!(medical_certificate_validated_at: Time.current)
      @subscription.confirm! if @subscription.completed?
      redirect_back_or_to [:admin, @subscription], notice: t('.success'), status: :see_other
    end

    def destroy
      @subscription.medical_certificate.purge
      @subscription.update!(medical_certificate_validated_at: nil)
      redirect_back_or_to [:admin, @subscription], notice: t('.success'), status: :see_other
    end

    private

    def set_subscription!
      @subscription = Current.platform.subscriptions.find(params.expect(:subscription_id))
    end
  end
end
