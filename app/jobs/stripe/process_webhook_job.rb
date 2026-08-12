# frozen_string_literal: true

module Stripe
  class ProcessWebhookJob < ApplicationJob
    retry_on Stripe::APIConnectionError, Stripe::RateLimitError, Stripe::APIError,
             wait: :polynomially_longer, attempts: 8

    def perform(event_id)
      event = Stripe::Event.retrieve(event_id)
      return unless event.type == 'payment_intent.succeeded'

      ::Subscription.find_by(stripe_payment_intent_id: event.data.object.id)&.reconcile_stripe_payment!
    end
  end
end
