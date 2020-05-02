# frozen_string_literal: true

class PaySubscriptionService
  def initialize(subscription, stripe_token)
    @subscription = subscription
    @stripe_token = stripe_token
  end

  def perform!
    charge = Stripe::Charge.create(
      amount: @subscription.fee_cents,
      currency: 'eur',
      source: @stripe_token,
      description: @subscription.description
    )

    @subscription.update(stripe_charge_id: charge.id)
  rescue Stripe::InvalidRequestError
    false
  end
end
