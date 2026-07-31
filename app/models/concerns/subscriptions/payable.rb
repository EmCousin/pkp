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
      before_destroy :cancel_stripe_payment_intent

      attr_accessor :payment_intent_client_secret
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

    def verify_stripe_payment!(payment_intent_id:, payment_intent_client_secret:, redirect_status:)
      with_lock do
        next unless stripe_payment_intent_id?

        intent = Stripe::PaymentIntent.retrieve(stripe_payment_intent_id)
        next unless valid_payment_intent?(intent, payment_intent_id, payment_intent_client_secret, redirect_status)

        charge = Stripe::Charge.retrieve(intent.latest_charge)
        next unless valid_charge?(charge)

        record_stripe_payment!(charge)
      end
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

    def record_stripe_payment!(charge)
      update!(paid_at: Time.zone.at(charge.created), payment_method: :credit_card, stripe_charge_id: charge.id)
      confirm! if completed? && !archived?
    end

    def cancel_open_stripe_payment_intent_without_lock?
      return true if paid? || !stripe_payment_intent_id?

      intent = Stripe::PaymentIntent.retrieve(stripe_payment_intent_id)
      Stripe::PaymentIntent.cancel(stripe_payment_intent_id) unless intent.status == 'canceled'
      update!(stripe_payment_intent_id: nil)
      remove_instance_variable(:@stripe_payment_intent) if defined?(@stripe_payment_intent)
      true
    end

    def valid_payment_intent?(intent, payment_intent_id, client_secret, redirect_status)
      payment_intent_id == intent.id &&
        client_secret == intent.client_secret &&
        redirect_status == 'succeeded' &&
        intent.status == 'succeeded' &&
        intent.currency == 'eur' &&
        intent.amount_received == fee_cents
    end

    def valid_charge?(charge)
      charge.paid && charge.currency == 'eur' && charge.amount == fee_cents
    end

    def stripe_charge
      @stripe_charge ||= stripe_charge_id && Stripe::Charge.retrieve(stripe_charge_id)
    end

    def update_stripe_payment_intent
      Stripe::PaymentIntent.update(stripe_payment_intent_id, amount: fee_cents)
    end

    def cancel_stripe_payment_intent
      throw :abort unless cancel_open_stripe_payment_intent
    end
  end
end
