# frozen_string_literal: true

module Admin
  class MedicalCertificatesController < BaseController
    before_action :set_subscription!

    def update
      source = Subscriptions::MedicalCertificate.new(subscription: @subscription).source
      return redirect_back_or_to [:admin, @subscription], alert: t('.no_source'), status: :see_other if source.nil?

      source.update!(medical_certificate_validated_at: Time.current)
      @subscription.confirm! if @subscription.completed?
      redirect_back_or_to [:admin, @subscription], notice: t('.success'), status: :see_other
    end

    def destroy
      return redirect_back_or_to [:admin, @subscription], alert: t('.confirmed'), status: :see_other if @subscription.confirmed?

      medical_certificate = Subscriptions::MedicalCertificate.new(subscription: @subscription)
      return redirect_back_or_to [:admin, @subscription], alert: t('.in_use'), status: :see_other if medical_certificate.source_in_use?

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
