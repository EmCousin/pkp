# frozen_string_literal: true

module Webhook
  class StripesController < ApplicationController
    skip_forgery_protection
    skip_before_action :set_current_platform

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
      subscription = subscription_for(event.data.object)
      return unless subscription

      Current.set(platform: subscription.platform) { subscription.reconcile_stripe_payment! }
    end

    def subscription_for(payment_intent)
      platform_id = payment_intent.metadata&.[](:platform_id)
      return Subscription.find_by(stripe_payment_intent_id: payment_intent.id) if platform_id.blank?

      Platform.find(platform_id).subscriptions.find_by(stripe_payment_intent_id: payment_intent.id)
    end

    def webhook_secret
      Rails.application.credentials.dig(:stripe, :webhook_secret)
    end
  end
end
