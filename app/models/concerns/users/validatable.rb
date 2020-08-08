# frozen_string_literal: true

module Users
  module Validatable
    extend ActiveSupport::Concern

    included do
      include DeviseExtensions::Validatable

      validates :terms_of_service, acceptance: true

      with_options on: :account_setup do
        validates :phone_number, presence: true, phone: true
        validates :address, presence: true
        validates :zip_code, presence: true
        validates :city, presence: true
        validates :country, presence: true
      end
    end
  end
end
