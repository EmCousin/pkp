# frozen_string_literal: true

module Stripe
  class CreateCustomerJob < ApplicationJob
    def perform(user)
      stripe_customer = Customer.create
      user.update!(stripe_customer_id: stripe_customer.id)
    end
  end
end
