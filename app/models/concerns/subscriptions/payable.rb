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
                                   intent = Stripe::PaymentIntent.create(amount: fee_cents, currency: 'eur', description:)
                                   update!(stripe_payment_intent_id: intent.id)
                                   intent
                                 end
    end

    def verify_stripe_payment!(payment_intent_id:, payment_intent_client_secret:, redirect_status:)
      return unless payment_intent_id == stripe_payment_intent.id
      return unless payment_intent_client_secret == stripe_payment_intent.client_secret
      return unless redirect_status == 'succeeded'

      stripe_payment_intent_charge = Stripe::Charge.retrieve(stripe_payment_intent.latest_charge)
      update!(
        paid_at: Time.zone.at(stripe_payment_intent_charge.created),
        payment_method: :credit_card,
        stripe_charge_id: stripe_payment_intent_charge.id
      )

      confirm! if completed?
    end

    def mark_as_paid!(payment_method:, at: Time.current)
      update_columns(paid_at: at, payment_method:) # rubocop:disable Rails/SkipsModelValidations
    end

    def mark_as_not_paid!
      update_columns(paid_at: nil, payment_method: nil) # rubocop:disable Rails/SkipsModelValidations
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

    def stripe_charge
      @stripe_charge ||= stripe_charge_id && Stripe::Charge.retrieve(stripe_charge_id)
    end

    def update_stripe_payment_intent
      Stripe::PaymentIntent.update(stripe_payment_intent_id, amount: fee_cents)
    end
  end
end
