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

      before_save :update_stripe_payment_intent, if: %i[fee_changed? stripe_payment_intent_id?], unless: :paid?
      before_destroy { throw :abort unless cancel_open_stripe_payment_intent }

      attr_accessor :payment_intent_client_secret
      attr_writer :stripe_payment_intent
    end

    def stripe_payment_intent
      @stripe_payment_intent ||= with_lock do
        next if paid? || payment_proof.attached?

        stripe_payment_intent_id? ? Stripe::PaymentIntent.retrieve(stripe_payment_intent_id) : create_stripe_payment_intent
      end
    end

    def stripe_payment_intent_url
      "https://dashboard.stripe.com/payments/#{stripe_payment_intent_id}"
    end

    def mark_as_paid!(payment_method:, at: Time.current)
      with_lock { update(paid_at: at, payment_method:).tap { restore_attributes(%w[paid_at payment_method]) unless it } }
    end

    def mark_as_not_paid!
      with_lock do
        update(paid_at: nil, payment_method: nil).tap { restore_attributes(%w[paid_at payment_method]) unless it }
      end
    end

    def paid?
      paid_at?
    end

    def approve_payment_proof!(payment_method:, at: Time.current)
      mark_as_paid!(at:, payment_method:) if payment_proof.attached?
    end

    def cancel_open_stripe_payment_intent
      with_lock { cancel_open_stripe_payment_intent_without_lock? }
    rescue Stripe::StripeError
      errors.add(:base, :stripe_payment_in_progress)
      false
    end

    def paid_amount
      return 0 unless paid?

      paid_via_credit_card? ? stripe_charge.amount / 100.0 : fee
    end

    def balance
      fee - paid_amount
    end

    def payable_by_credit_card?
      event?
    end

    private

    def create_stripe_payment_intent
      intent = Stripe::PaymentIntent.create(amount: fee_cents, currency: 'eur', description:,
                                            customer: member.user.stripe_customer_id)
      update!(stripe_payment_intent_id: intent.id)
      intent
    end

    def cancel_open_stripe_payment_intent_without_lock?
      return true if paid? || !stripe_payment_intent_id?

      intent = Stripe::PaymentIntent.retrieve(stripe_payment_intent_id)
      Stripe::PaymentIntent.cancel(stripe_payment_intent_id) unless intent.status == 'canceled'
      update!(stripe_payment_intent_id: nil)
      self.stripe_payment_intent = nil
      true
    end

    def stripe_charge
      @stripe_charge ||= stripe_charge_id && Stripe::Charge.retrieve(stripe_charge_id)
    end

    def update_stripe_payment_intent
      Stripe::PaymentIntent.update(stripe_payment_intent_id, amount: fee_cents)
    end
  end
end
