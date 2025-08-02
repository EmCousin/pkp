# frozen_string_literal: true

module Subscriptions
  module Payable
    extend ActiveSupport::Concern

    PAYMENT_METHODS = {
      cash: 'cash',
      bank_transfer: 'bank_transfer',
      bank_check: 'bank_check',
      credit_card: 'credit_card'
    }.freeze

    included do
      has_one_attached :payment_proof

      enum :payment_method, PAYMENT_METHODS, prefix: :paid_via
    end

    def pay_with_stripe!(stripe_token)
      charge = create_stripe_charge(stripe_token)
      self.stripe_charge_id = charge.id
      self.paid_at = Time.zone.at(charge.created) if charge.paid && charge.amount == fee_cents
      self.payment_method = :credit_card
      save!
    rescue Stripe::InvalidRequestError
      false
    end

    def mark_as_paid!(payment_method:, at: Time.current)
      update!(paid_at: at, payment_method:)
    end

    def mark_as_not_paid!
      update!(paid_at: nil, payment_method: nil)
    end

    def paid?
      paid_at?
    end

    def approve_payment_proof!(payment_method:, at: Time.current)
      mark_as_paid!(at:, payment_method:) if payment_proof.attached?
    end

    def paid_amount
      return 0 unless paid?

      paid_via_credit_card? ? stripe_charge.amount / 100.0 : fee
    end

    def balance
      fee - paid_amount
    end

    def payable_by_credit_card?
      subscription_camp.present?
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
