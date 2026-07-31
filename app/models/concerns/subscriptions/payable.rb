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

      attr_accessor :payment_intent_client_secret
    end

    def stripe_payment_intent
      @stripe_payment_intent ||= if stripe_payment_intent_id?
                                   Stripe::PaymentIntent.retrieve(stripe_payment_intent_id)
                                 else
                                   intent = Stripe::PaymentIntent.create(amount: fee_cents, currency: 'eur', description:,
                                                                         customer: member.user.stripe_customer_id)
                                   update!(stripe_payment_intent_id: intent.id)
                                   intent
                                 end
    end

    def stripe_payment_intent_url
      "https://dashboard.stripe.com/payments/#{stripe_payment_intent_id}"
    end

    def verify_stripe_payment!(payment_intent_id:, payment_intent_client_secret:, redirect_status:)
      intent = stripe_payment_intent
      return unless valid_payment_intent?(intent, payment_intent_id, payment_intent_client_secret, redirect_status)

      charge = Stripe::Charge.retrieve(intent.latest_charge)
      return unless valid_charge?(charge)

      update!(
        paid_at: Time.zone.at(charge.created),
        payment_method: :credit_card,
        stripe_charge_id: charge.id
      )

      confirm! if completed?
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
      event?
    end

    private

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
  end
end
