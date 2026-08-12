# frozen_string_literal: true

module Webhook
  class StripesController < ApplicationController
    skip_forgery_protection

    def create
      return head :service_unavailable if webhook_secret.blank?

      event = Stripe::Webhook.construct_event(
        request.raw_post,
        request.headers['Stripe-Signature'],
        webhook_secret
      )
      reconcile_payment(event) if event.type == 'payment_intent.succeeded'

      head :ok
    rescue JSON::ParserError, Stripe::SignatureVerificationError
      head :bad_request
    end

    private

    def reconcile_payment(event)
      Subscription.find_by(stripe_payment_intent_id: event.data.object.id)&.reconcile_stripe_payment!
    end

    def webhook_secret
      Rails.application.credentials.dig(:stripe, :webhook_secret)
    end
  end
end
