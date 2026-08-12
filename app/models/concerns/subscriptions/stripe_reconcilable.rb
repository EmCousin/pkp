# frozen_string_literal: true

module Subscriptions
  module StripeReconcilable
    extend ActiveSupport::Concern

    def verify_stripe_payment!(payment_intent_id:, payment_intent_client_secret:, redirect_status:)
      with_lock do
        next if paid?
        next unless stripe_payment_intent_id?

        intent = Stripe::PaymentIntent.retrieve(stripe_payment_intent_id)
        next unless valid_payment_return?(intent, payment_intent_id, payment_intent_client_secret, redirect_status)
        next unless valid_payment_intent?(intent)

        reconcile_stripe_payment_intent!(intent)
      end
    end

    def reconcile_stripe_payment!
      with_lock do
        next if paid?
        next unless stripe_payment_intent_id?

        intent = Stripe::PaymentIntent.retrieve(stripe_payment_intent_id)
        reconcile_stripe_payment_intent!(intent) if valid_payment_intent?(intent)
      end
    end

    private

    def valid_payment_return?(intent, payment_intent_id, client_secret, redirect_status)
      payment_intent_id == intent.id &&
        client_secret == intent.client_secret &&
        redirect_status == 'succeeded'
    end

    def valid_payment_intent?(intent)
      intent.id == stripe_payment_intent_id &&
        intent.status == 'succeeded' &&
        intent.currency == 'eur' &&
        intent.amount_received == fee_cents
    end

    def valid_charge?(charge)
      charge.paid && charge.amount_refunded.zero? && charge.currency == 'eur' && charge.amount == fee_cents
    end

    def reconcile_stripe_payment_intent!(intent)
      charge = Stripe::Charge.retrieve(intent.latest_charge)
      return unless valid_charge?(charge)

      update!(paid_at: Time.zone.at(charge.created), payment_method: :credit_card, stripe_charge_id: charge.id)
      confirm! if completed? && !archived?
    end
  end
end
