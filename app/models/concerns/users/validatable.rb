# frozen_string_literal: true

module Users
  module Validatable
    extend ActiveSupport::Concern

    included do
      include DeviseExtensions::Validatable

      validate :valid_email_provider, if: :email?, on: :create
      validates :terms_of_service, acceptance: true

      with_options on: :account_setup do
        validates :phone_number, presence: true, phone: true
        validates :address, presence: true
        validates :zip_code, presence: true
        validates :city, presence: true
        validates :country, presence: true
      end
    end

    def invalid_email_provider?
      INVALID_EMAIL_PROVIDERS.any? { |provider| email.ends_with?(provider) }
    end

    private

    INVALID_EMAIL_PROVIDERS = %w[@wanadoo.fr @orange.fr].freeze

    def valid_email_provider
      errors.add(:email, :invalid_provider) if invalid_email_provider?
    end
  end
end
