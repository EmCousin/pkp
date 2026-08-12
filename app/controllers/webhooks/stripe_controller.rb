# frozen_string_literal: true

module Webhooks
  class StripeController < ApplicationController
    skip_forgery_protection

    def create
      return head :service_unavailable if webhook_secret.blank?

      event = Stripe::Webhook.construct_event(
        request.raw_post,
        request.headers['Stripe-Signature'],
        webhook_secret
      )
      Stripe::ProcessWebhookJob.perform_later(event.id) if event.type == 'payment_intent.succeeded'

      head :ok
    rescue JSON::ParserError, Stripe::SignatureVerificationError
      head :bad_request
    end

    private

    def webhook_secret
      Rails.application.credentials.dig(:stripe, :webhook_secret)
    end
  end
end
