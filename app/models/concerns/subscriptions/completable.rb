# frozen_string_literal: true

module Subscriptions
  module Completable
    extend ActiveSupport::Concern

    included do
      attribute :terms_accepted, :boolean, default: false
      attribute :medical_certificate, :boolean, default: false

      has_one_attached :form
    end

    def completed?
      paid? && terms_accepted_at? && doctor_certified_at?
    end

    def pending_confirmation?
      pending? && completed?
    end

    def terms_accepted=(value)
      accepted = super
      self.terms_accepted_at = accepted ? Time.current : nil
    end

    def medical_certificate=(value)
      certified = super
      self.doctor_certified_at = certified ? Time.current : nil
    end
  end
end
