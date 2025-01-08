# frozen_string_literal: true

module Subscriptions
  module Completable
    extend ActiveSupport::Concern

    included do
      has_one_attached :form
      has_one_attached :signed_form
      has_one_attached :medical_certificate
      has_one_attached :payment_proof
    end

    def needs_medical_certificate?
      previous_subscription.nil? || !previous_subscription.confirmed?
    end

    def previous_subscription
      @previous_subscription ||= member.subscriptions.find_by(year: [year - 1, year - 2])
    end

    def completed?
      (paid? || payment_proof.attached?) && signed_form.attached? && medical_certificate.attached?
    end
  end
end
