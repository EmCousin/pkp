# frozen_string_literal: true

module Members
  module Decoratable
    extend ActiveSupport::Concern

    included do
      delegate :email, :phone_number, :address, :zip_code, :city, :country,
               to: :user
    end

    def full_name
      "#{first_name} #{last_name}".downcase.titleize
    end

    def age(year = Time.current.year)
      year - birthdate.year
    end
  end
end
