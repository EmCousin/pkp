# frozen_string_literal: true

module DeviseExtensions
  module Validatable
    extend ActiveSupport::Concern

    included do
      attr_accessor :email_confirmation
      validates :email, confirmation: true, if: :email_confirmation_required?
    end

    private

    def email_confirmation_required?
      new_record? && email.present? && email_confirmation.present?
    end
  end
end
