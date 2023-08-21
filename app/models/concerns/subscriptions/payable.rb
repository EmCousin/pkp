# frozen_string_literal: true

module Subscriptions
  module Payable
    extend ActiveSupport::Concern

    def pay!(stripe_token)
      update(stripe_charge_id: create_stripe_charge(stripe_token).id)
    rescue Stripe::InvalidRequestError
      false
    end

    def paid?
      return false if stripe_charge.blank?

      stripe_charge.paid && stripe_charge.amount == fee_cents
    end

    def paid_at
      Time.zone.at(stripe_charge.created)
    end

    def paid_amount
      stripe_charge.amount / 100.0
    end

    def balance
      fee - paid_amount
    end

    private

    def create_stripe_charge(stripe_token)
      Stripe::Charge.create(
        amount: fee_cents,
        currency: 'eur',
        source: stripe_token,
        description:
      )
    end

    def stripe_charge
      @stripe_charge ||= stripe_charge_id && Stripe::Charge.retrieve(stripe_charge_id)
    end
  end
end
