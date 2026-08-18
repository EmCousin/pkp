# frozen_string_literal: true

module Subscriptions
  module Completable
    extend ActiveSupport::Concern

    included do
      attribute :terms_accepted, :boolean, default: false
      attribute :doctor_certified, :boolean, default: false

      has_one_attached :form
      has_one_attached :medical_certificate

      scope :with_direct_medical_certificate, lambda {
        where.not(doctor_certified_at: nil).joins(:medical_certificate_attachment)
      }
    end

    def completed?(medical_certificate: medical_certificate_record)
      return paid? && terms_accepted_at? unless medical_certificate_required?

      paid? && terms_accepted_at? && medical_certificate.valid?
    end

    def medical_certificate_valid?
      medical_certificate_record.valid?
    end

    def medical_certificate_source
      medical_certificate_record.source
    end

    def effective_medical_certificate
      medical_certificate_record.attachment
    end

    def inherited_medical_certificate?
      medical_certificate_record.inherited?
    end

    def medical_certificate_source_in_use?
      medical_certificate_record.source_in_use?
    end

    def medical_certificate_record
      Subscriptions::MedicalCertificate.new(subscription: self)
    end

    def pending_confirmation?(medical_certificate: medical_certificate_record)
      pending? && completed?(medical_certificate:)
    end

    def terms_accepted=(value)
      accepted = super
      self.terms_accepted_at = accepted ? Time.current : nil
    end

    def doctor_certified=(value)
      certified = super
      self.doctor_certified_at = certified ? Time.current : nil
    end
  end
end
