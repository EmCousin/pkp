# frozen_string_literal: true

class CreateSubscriptionService
  def initialize(subscription)
    @subscription = subscription
  end

  def perform!
    @subscription.year = Time.now.year
    @subscription.fee = 0
    if @subscription.save
      @subscription.fee = @subscription.compute_fee
      @subscription.save
    end

    @subscription
  end
end
