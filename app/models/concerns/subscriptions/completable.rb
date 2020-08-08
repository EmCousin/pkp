# frozen_string_literal: true

module Subscriptions
  module Completable
    extend ActiveSupport::Concern

    included do
      has_one_attached :form
      has_one_attached :signed_form
      has_one_attached :medical_certificate

      attr_accessor :category
    end

    def completed?
      paid? && signed_form.attached? && medical_certificate.attached?
    end
  end
end
