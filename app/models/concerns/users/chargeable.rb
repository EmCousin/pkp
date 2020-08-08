# frozen_string_literal: true

module Users
  module Chargeable
    extend ActiveSupport::Concern

    included do
      after_create :create_stripe_customer_id
    end

    private

    def create_stripe_customer_id
      Stripe::CreateCustomerJob.perform_later(self)
    end
  end
end
