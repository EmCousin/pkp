# frozen_string_literal: true

module Users
  module Chargeable
    extend ActiveSupport::Concern

    included do
      after_create :create_stripe_customer_id_later
    end

    def stripe_customer
      @stripe_customer ||= stripe_customer_id.presence && Stripe::Customer.retrieve(stripe_customer_id)
    end

    def create_stripe_customer_id
      stripe_customer = Stripe::Customer.create(email: email)
      update!(stripe_customer_id: stripe_customer.id)
    end

    private

    def create_stripe_customer_id_later
      Stripe::CreateCustomerJob.perform_later(self)
    end
  end
end
