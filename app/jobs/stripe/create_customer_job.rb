# frozen_string_literal: true

module Stripe
  class CreateCustomerJob < ApplicationJob
    def perform(user)
      user.create_stripe_customer_id
    end
  end
end
